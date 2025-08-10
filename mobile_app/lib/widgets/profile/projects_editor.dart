import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../utils/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../modern/modern_text_field.dart';
import '../modern/modern_button.dart';

class ProjectsEditor extends StatefulWidget {
  final List<ProjectModel> projects;
  final Function(List<ProjectModel>) onProjectsChanged;

  const ProjectsEditor({
    super.key,
    required this.projects,
    required this.onProjectsChanged,
  });

  @override
  State<ProjectsEditor> createState() => _ProjectsEditorState();
}

class _ProjectsEditorState extends State<ProjectsEditor> {
  late List<ProjectModel> _projects;

  @override
  void initState() {
    super.initState();
    _projects = List.from(widget.projects);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.lightGrayColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: AppTheme.secondaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Text(
                    l10n.projects,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _addProject,
                icon: Icon(
                  Icons.add_circle,
                  color: AppTheme.secondaryColor,
                  size: 28,
                ),
                tooltip: l10n.addProject,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceSm),

          Text(
            l10n.showcaseYourProjects,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grayColor,
                ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // Projects List
          if (_projects.isEmpty)
            _buildEmptyState()
          else
            ..._projects.asMap().entries.map((entry) {
              final index = entry.key;
              final project = entry.value;
              return _buildProjectCard(project, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.lightGrayColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.lightGrayColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: AppTheme.grayColor,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            AppLocalizations.of(context).noProjectsAdded,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.grayColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            AppLocalizations.of(context).tapAddToStartAdding,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grayColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.lightGrayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.lightGrayColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editProject(project, index),
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                    tooltip: AppLocalizations.of(context).edit,
                  ),
                  IconButton(
                    onPressed: () => _deleteProject(index),
                    icon: Icon(
                      Icons.delete,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    tooltip: AppLocalizations.of(context).delete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.grayColor,
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                _formatDateRange(project.startDate, project.endDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grayColor,
                    ),
              ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              project.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Wrap(
              spacing: AppTheme.spaceXs,
              runSpacing: AppTheme.spaceXs,
              children: project.technologies
                  .map((tech) => Chip(
                        label: Text(
                          tech,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        backgroundColor:
                            AppTheme.secondaryColor.withOpacity(0.1),
                        side: BorderSide(
                            color: AppTheme.secondaryColor.withOpacity(0.3)),
                      ))
                  .toList(),
            ),
          ],
          if (project.projectUrl != null && project.projectUrl!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                Expanded(
                  child: Text(
                    project.projectUrl!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(DateTime startDate, DateTime? endDate) {
    final start = '${startDate.month}/${startDate.year}';
    final end =
        endDate != null ? '${endDate.month}/${endDate.year}' : 'Ongoing';
    return '$start - $end';
  }

  void _addProject() {
    _showProjectDialog();
  }

  void _editProject(ProjectModel project, int index) {
    _showProjectDialog(project: project, index: index);
  }

  void _deleteProject(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteProject),
        content: Text(AppLocalizations.of(context).deleteProjectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _projects.removeAt(index);
              });
              widget.onProjectsChanged(_projects);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context).delete,
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectDialog({ProjectModel? project, int? index}) {
    final titleController = TextEditingController(text: project?.title ?? '');
    final descriptionController =
        TextEditingController(text: project?.description ?? '');
    final urlController =
        TextEditingController(text: project?.projectUrl ?? '');
    final technologiesController = TextEditingController(
      text: project?.technologies.join(', ') ?? '',
    );

    DateTime startDate = project?.startDate ?? DateTime.now();
    DateTime? endDate = project?.endDate;
    bool isOngoing = endDate == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            project == null
                ? AppLocalizations.of(context).addProject
                : AppLocalizations.of(context).editProject,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(
                  controller: titleController,
                  label: AppLocalizations.of(context).projectTitle,
                  icon: Icons.folder,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)
                          .pleaseEnterProjectTitle;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: descriptionController,
                  label: AppLocalizations.of(context).description,
                  icon: Icons.description,
                  maxLines: 3,
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: technologiesController,
                  label: AppLocalizations.of(context).technologies,
                  icon: Icons.code,
                  hintText: 'e.g., Flutter, Firebase, Node.js',
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: urlController,
                  label: AppLocalizations.of(context).projectUrl,
                  icon: Icons.link,
                  hintText: 'https://github.com/username/project',
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // Date pickers would go here
                // For now, using simple text display
                Text('Start Date: ${startDate.month}/${startDate.year}'),
                if (!isOngoing && endDate != null)
                  Text('End Date: ${endDate!.month}/${endDate!.year}'),

                CheckboxListTile(
                  title: Text(AppLocalizations.of(context).ongoingProject),
                  value: isOngoing,
                  onChanged: (value) {
                    setDialogState(() {
                      isOngoing = value ?? false;
                      if (isOngoing) {
                        endDate = null;
                      } else {
                        endDate = DateTime.now();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ModernButton(
              text: AppLocalizations.of(context).save,
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final technologies = technologiesController.text
                      .split(',')
                      .map((tech) => tech.trim())
                      .where((tech) => tech.isNotEmpty)
                      .toList();

                  final newProject = ProjectModel(
                    id: project?.id ??
                        'proj_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    technologies: technologies,
                    startDate: startDate,
                    endDate: isOngoing ? null : endDate,
                    projectUrl: urlController.text.trim().isEmpty
                        ? null
                        : urlController.text.trim(),
                  );

                  setState(() {
                    if (index != null) {
                      _projects[index] = newProject;
                    } else {
                      _projects.add(newProject);
                    }
                  });

                  widget.onProjectsChanged(_projects);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
