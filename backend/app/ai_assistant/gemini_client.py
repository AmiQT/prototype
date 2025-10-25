"""Google Gemini API client with tool calling support."""

import json
import logging
import collections.abc
from typing import Any, Dict, List
import google.generativeai as genai

logger = logging.getLogger(__name__)


class GeminiClient:
    """Client for Google Gemini API with function calling."""
    
    def __init__(self, api_key: str):
        """Initialize Gemini client."""
        self.api_key = api_key
        genai.configure(api_key=api_key)
        
        # Use Gemini 2.0 Flash - best free model with tool support
        self.model = genai.GenerativeModel('gemini-2.0-flash-exp')
        
        logger.info("✅ Gemini client initialized with model: gemini-2.0-flash-exp")

    def _convert_repeated_composite_to_list(self, value: Any) -> Any:
        """Recursively converts protobuf RepeatedComposite to a list and maps to dicts."""
        if isinstance(value, collections.abc.Sequence) and not isinstance(value, (str, bytes)):
            return [self._convert_repeated_composite_to_list(item) for item in value]
        if isinstance(value, collections.abc.Mapping):
            return {k: self._convert_repeated_composite_to_list(v) for k, v in value.items()}
        return value
    
    def _convert_openai_type_to_gemini(self, openai_type: str) -> str:
        """Convert OpenAI JSON Schema types to Gemini format."""
        type_mapping = {
            "string": "STRING",
            "number": "NUMBER",
            "integer": "INTEGER",
            "boolean": "BOOLEAN",
            "array": "ARRAY",
            "object": "OBJECT"
        }
        return type_mapping.get(openai_type.lower(), "STRING")
    
    def _convert_schema_to_gemini(self, schema: Dict[str, Any], is_top_level: bool = False) -> Dict[str, Any]:
        """Recursively convert OpenAI JSON Schema to Gemini format."""
        gemini_schema = {}
        
        # Convert type
        if "type" in schema:
            gemini_schema["type"] = self._convert_openai_type_to_gemini(schema["type"])
        
        # Convert properties (for objects)
        if "properties" in schema:
            gemini_props = {}
            for prop_name, prop_def in schema["properties"].items():
                gemini_props[prop_name] = self._convert_schema_to_gemini(prop_def, is_top_level=False)
            gemini_schema["properties"] = gemini_props
        
        # Handle 'required' only at top level (object with properties)
        if is_top_level and "required" in schema:
            gemini_schema["required"] = schema["required"]
        
        # Copy only Gemini-supported fields (NO "default", NO "required" for nested!)
        for key in ["description", "enum", "format"]:
            if key in schema:
                gemini_schema[key] = schema[key]
        
        # Handle array items
        if "items" in schema:
            gemini_schema["items"] = self._convert_schema_to_gemini(schema["items"], is_top_level=False)
        
        return gemini_schema
    
    def _convert_protobuf_value(self, value) -> Any:
        """Convert protobuf value to Python native type."""
        try:
            # Handle different protobuf value types
            if hasattr(value, 'string_value'):
                return value.string_value
            elif hasattr(value, 'number_value'):
                return value.number_value
            elif hasattr(value, 'bool_value'):
                return value.bool_value
            elif hasattr(value, 'list_value'):
                return [self._convert_protobuf_value(item) for item in value.list_value.values]
            elif hasattr(value, 'struct_value'):
                return {k: self._convert_protobuf_value(v) for k, v in value.struct_value.fields.items()}
            elif hasattr(value, 'null_value'):
                return None
            elif hasattr(value, 'values'):
                # Handle repeated fields directly
                return [self._convert_protobuf_value(item) for item in value.values]
            elif hasattr(value, 'fields'):
                # Handle struct fields directly
                return {k: self._convert_protobuf_value(v) for k, v in value.fields.items()}
            else:
                # Fallback: try to get the actual value
                if hasattr(value, 'value'):
                    return value.value
                else:
                    # Last resort: convert to string
                    return str(value)
        except Exception as e:
            logger.warning(f"Failed to convert protobuf value: {e}, using string representation")
            return str(value)
    
    def _convert_tools_to_gemini_format(self, tools: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Convert OpenAI-style tools to Gemini format.
        
        OpenAI format:
        {
            "type": "function",
            "function": {
                "name": "query_students",
                "description": "...",
                "parameters": {"type": "object", "properties": {...}}
            }
        }
        
        Gemini format:
        {
            "name": "query_students",
            "description": "...",
            "parameters": {"type": "OBJECT", "properties": {...}}
        }
        """
        gemini_tools = []
        
        for tool in tools:
            if tool.get("type") == "function":
                function = tool["function"]
                gemini_tool = {
                    "name": function["name"],
                    "description": function["description"],
                    "parameters": self._convert_schema_to_gemini(function["parameters"], is_top_level=True)
                }
                gemini_tools.append(gemini_tool)
        
        logger.info(f"🔧 Converted {len(gemini_tools)} tools to Gemini format")
        return gemini_tools
    
    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        tools: List[Dict[str, Any]] | None = None,
        max_tokens: int = 800,
        temperature: float = 0.7,
    ) -> str | Dict[str, Any]:
        """
        Generate chat completion with optional tool calling.
        
        Returns:
            - str: Final text response
            - Dict: Tool calls if AI wants to use tools
        """
        try:
            # Convert messages to Gemini format
            history = []
            current_message = None
            
            for msg in messages:
                role = msg["role"]
                content = msg["content"]
                
                if role == "system":
                    # Gemini doesn't have system role, prepend to first user message
                    continue
                elif role == "user":
                    current_message = content
                elif role == "assistant":
                    if content:
                        history.append({
                            "role": "user",
                            "parts": [current_message]
                        })
                        history.append({
                            "role": "model",
                            "parts": [content]
                        })
                elif role == "tool":
                    # Tool results will be handled in agentic loop
                    continue
            
            # Setup generation config
            generation_config = {
                "temperature": temperature,
                "max_output_tokens": max_tokens,
            }
            
            # Convert tools if provided
            gemini_tools = None
            if tools:
                gemini_tools = self._convert_tools_to_gemini_format(tools)
            
            # Create chat session
            if gemini_tools:
                # Enable function calling
                model_with_tools = genai.GenerativeModel(
                    'gemini-2.0-flash-exp',
                    tools=gemini_tools
                )
                chat = model_with_tools.start_chat(history=history)
            else:
                chat = self.model.start_chat(history=history)
            
            # Get last user message
            last_user_message = messages[-1]["content"] if messages else ""
            
            # Generate response
            response = chat.send_message(
                last_user_message,
                generation_config=generation_config
            )
            
            # Check if model wants to call functions
            if response.candidates and response.candidates[0].content.parts:
                part = response.candidates[0].content.parts[0]
                
                # Check for function call
                if hasattr(part, 'function_call') and part.function_call:
                    function_call = part.function_call
                    
                    logger.info(f"🔧 Gemini requested function: {function_call.name}")
                    
                    # Convert function arguments to proper JSON
                    args_dict = self._convert_repeated_composite_to_list(function_call.args) if function_call.args else {}
                    
                    # Convert to OpenAI-style tool call format
                    tool_call = {
                        "id": f"call_{function_call.name}",
                        "type": "function",
                        "function": {
                            "name": function_call.name,
                            "arguments": json.dumps(args_dict)  # ✅ Proper JSON format!
                        }
                    }
                    
                    return {
                        "type": "tool_calls",
                        "tool_calls": [tool_call],
                        "message": {
                            "role": "assistant",
                            "content": None,
                            "tool_calls": [tool_call]
                        }
                    }
            
            # Regular text response
            text = response.text
            logger.info(f"✅ Gemini text response: {len(text)} chars")
            
            return text
            
        except Exception as e:
            logger.error(f"Gemini API error: {e}", exc_info=True)
            raise RuntimeError(f"Gemini API error: {str(e)}")

