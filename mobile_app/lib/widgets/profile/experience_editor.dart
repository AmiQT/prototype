import 'package:flutter/material.dart';
import '../../models/experience_model.dart';
import '../../utils/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../modern/modern_text_field.dart';
import '../modern/modern_button.dart';

class ExperienceEditor extends StatefulWidget {
  final List<ExperienceModel> experiences;
  final Function(List<ExperienceModel>) onExperiencesChanged;

  const ExperienceEditor({
    super.key,
    required this.experiences,
    required this.onExperiencesChanged,
  });

  @override
  State<ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends State<ExperienceEditor> {
  late List<ExperienceModel> _experiences;

  @override
  void initState() {
    super.initState();
    _experiences = List.from(widget.experiences);
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
                    Icons.work,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Text(
                    l10n.experience,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _addExperience,
                icon: Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                tooltip: l10n.addExperience,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceSm),

          Text(
            l10n.addYourWorkExperience,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grayColor,
                ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // Experience List
          if (_experiences.isEmpty)
            _buildEmptyState()
          else
            ..._experiences.asMap().entries.map((entry) {
              final index = entry.key;
              final experience = entry.value;
              return _buildExperienceCard(experience, index);
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
            Icons.work_outline,
            size: 48,
            color: AppTheme.grayColor,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            AppLocalizations.of(context).noExperienceAdded,
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

  Widget _buildExperienceCard(ExperienceModel experience, int index) {
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
                  experience.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editExperience(experience, index),
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    tooltip: AppLocalizations.of(context).edit,
                  ),
                  IconButton(
                    onPressed: () => _deleteExperience(index),
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
          if (experience.company.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: AppTheme.grayColor,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  experience.company,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
          if (experience.location?.isNotEmpty == true) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.grayColor,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  experience.location!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
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
                _formatDateRange(experience.startDate, experience.endDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grayColor,
                    ),
              ),
            ],
          ),
          if (experience.description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              experience.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(DateTime startDate, DateTime? endDate) {
    final start = '${startDate.month}/${startDate.year}';
    final end =
        endDate != null ? '${endDate.month}/${endDate.year}' : 'Present';
    return '$start - $end';
  }

  void _addExperience() {
    _showExperienceDialog();
  }

  void _editExperience(ExperienceModel experience, int index) {
    _showExperienceDialog(experience: experience, index: index);
  }

  void _deleteExperience(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteExperience),
        content:
            Text(AppLocalizations.of(context).deleteExperienceConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _experiences.removeAt(index);
              });
              widget.onExperiencesChanged(_experiences);
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

  void _showExperienceDialog({ExperienceModel? experience, int? index}) {
    final titleController =
        TextEditingController(text: experience?.title ?? '');
    final companyController =
        TextEditingController(text: experience?.company ?? '');
    final locationController =
        TextEditingController(text: experience?.location ?? '');
    final descriptionController =
        TextEditingController(text: experience?.description ?? '');

    DateTime startDate = experience?.startDate ?? DateTime.now();
    DateTime? endDate = experience?.endDate;
    bool isCurrentJob = endDate == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            experience == null
                ? AppLocalizations.of(context).addExperience
                : AppLocalizations.of(context).editExperience,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(
                  controller: titleController,
                  label: AppLocalizations.of(context).jobTitle,
                  icon: Icons.work,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).pleaseEnterJobTitle;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: companyController,
                  label: AppLocalizations.of(context).company,
                  icon: Icons.business,
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: locationController,
                  label: AppLocalizations.of(context).location,
                  icon: Icons.location_on,
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // Date pickers would go here
                // For now, using simple text display
                Text('Start Date: ${startDate.month}/${startDate.year}'),
                if (!isCurrentJob && endDate != null)
                  Text('End Date: ${endDate!.month}/${endDate!.year}'),

                CheckboxListTile(
                  title: Text(AppLocalizations.of(context).currentlyWorking),
                  value: isCurrentJob,
                  onChanged: (value) {
                    setDialogState(() {
                      isCurrentJob = value ?? false;
                      if (isCurrentJob) {
                        endDate = null;
                      } else {
                        endDate = DateTime.now();
                      }
                    });
                  },
                ),

                const SizedBox(height: AppTheme.spaceMd),

                ModernTextField(
                  controller: descriptionController,
                  label: AppLocalizations.of(context).description,
                  icon: Icons.description,
                  maxLines: 3,
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
                  final newExperience = ExperienceModel(
                    id: experience?.id ??
                        'exp_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    company: companyController.text.trim(),
                    location: locationController.text.trim(),
                    description: descriptionController.text.trim(),
                    startDate: startDate,
                    endDate: isCurrentJob ? null : endDate,
                    isCurrentPosition: isCurrentJob,
                  );

                  setState(() {
                    if (index != null) {
                      _experiences[index] = newExperience;
                    } else {
                      _experiences.add(newExperience);
                    }
                  });

                  widget.onExperiencesChanged(_experiences);
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
