import 'package:pocketcrm/shared/widgets/custom_field_edit_dialog.dart';
import 'package:pocketcrm/presentation/shared/edit_fields_sheet.dart';
import 'package:pocketcrm/core/di/dynamic_preferences_provider.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/domain/models/metadata/field_metadata.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/presentation/shared/linked_contacts_widget.dart';
import 'package:pocketcrm/presentation/shared/note_card.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/core/utils/demo_utils.dart';
import 'package:pocketcrm/presentation/shared/dialog_helper.dart';
import 'package:pocketcrm/presentation/companies/companies_screen.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';
import 'package:pocketcrm/presentation/workflows/workflow_action_button.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CompanyDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}
class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  IconData _getIconForFieldType(String type) {
    switch (type.toUpperCase()) {
      case 'TEXT': return Icons.text_fields;
      case 'NUMBER': return Icons.numbers;
      case 'BOOLEAN': return Icons.check_box;
      case 'DATE':
      case 'DATE_TIME': return Icons.calendar_today;
      case 'CURRENCY': return Icons.attach_money;
      case 'SELECT':
      case 'MULTI_SELECT': return Icons.list;
      case 'EMAIL': return Icons.email;
      case 'PHONE': return Icons.phone;
      case 'URL':
      case 'LINKS': return Icons.link;
      default: return Icons.tune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(companyDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.companyDetails ?? 'Company Details'),
        actions: [
          if (detailAsync.hasValue)
            WorkflowActionButton(
              objectType: 'company',
              recordId: widget.id,
            ),
          if (detailAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n?.editCompany ?? 'Edit company',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => EditCompanySheet(company: detailAsync.value!),
                );
              },
            ),
          if (detailAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n?.deleteCompany ?? 'Delete company',
              onPressed: () async {
                if (!await DemoUtils.checkDemoAction(context, ref)) return;

                final confirm = await DialogHelper.showDeleteConfirmDialog(
                  context: context,
                  title: l10n?.deleteCompany ?? 'Delete company',
                  message:
                      l10n?.deleteCompanyConfirmMessage(detailAsync.value!.name) ??
                      'Are you sure you want to delete ${detailAsync.value!.name}?\nThis action cannot be undone.',
                );

                if (confirm && context.mounted) {
                  try {
                    await ref
                        .read(companiesProvider.notifier)
                        .deleteCompany(widget.id);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      SnackbarHelper.showSuccess(context, l10n?.companyDeleted ?? 'Company deleted');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarHelper.showError(
                        context,
                        l10n?.errorDuringDeletion ?? 'Error during deletion',
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      floatingActionButton: detailAsync.whenOrNull(
        data: (company) => FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => _AddCompanyNoteSheet(companyId: company.id),
            );
          },
          icon: const Icon(Icons.add),
          label: Text(l10n?.newNote ?? 'New Note'),
        ),
      ),
      body: detailAsync.when(
        data: (company) => _buildDetail(context, company),
        loading: () => const DetailSkeleton(),
        error: (err, stack) => ErrorStateWidget(
          title: l10n?.loadingError ?? 'Error loading details',
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(companyDetailProvider(widget.id)),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Company company) {
    final l10n = AppLocalizations.of(context);
    final metadataAsync = ref.watch(workspaceMetadataProvider);
    List<FieldMetadata> companyFields = [];
    ObjectMetadata? companyMetadata;
    if (metadataAsync.hasValue) {
      companyMetadata = metadataAsync.value!.where((e) => e.nameSingular.toLowerCase() == 'company').firstOrNull;
      if (companyMetadata != null) {
        const standardCompanyFields = {
          'id', 'name', 'domainName', 'createdAt', 'updatedAt', 'deletedAt', 'createdBy', 
          'updatedBy', 'employees', 'revenue', 'industry', 'linkedinLink', 'xLink', 
          'annualRecurringRevenue', 'address', 'accountOwner', 'idealCustomerProfile', 'logoUrl',
          'position', 'searchVector'
        };
        const excludedFieldTypes = {
          'RELATION', 'MULTI_SELECT', 'RICH_TEXT', 'LINKS', 'PHONES', 'EMAILS', 'ADDRESS',
        };
        final stdLower = standardCompanyFields.map((s) => s.toLowerCase()).toSet();
        companyFields = companyMetadata.fields
            .where((f) => f.isActive && !stdLower.contains(f.name.toLowerCase()) && !f.name.toLowerCase().contains('search') && !f.name.toLowerCase().contains('position') && !excludedFieldTypes.contains(f.type))
            .toList();
      }
    }
    // The person can hide and reorder these fields (stored on the device, like for custom objects).
    final companyFieldNames = companyFields.map((f) => f.name).toList();
    companyFields = applyFieldPrefs(companyFields, ref.watch(dynamicFieldPrefsProvider('company')));

    return ConstrainedContent(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: company.logoUrl != null
                ? CachedNetworkImageProvider(company.logoUrl!)
                : null,
            child: company.logoUrl == null
                ? const Icon(Icons.business, size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            company.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (company.domainName != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://${company.domainName}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                company.domainName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                if (company.industry != null)
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(company.industry!),
                    subtitle: Text(l10n?.industry ?? 'Industry'),
                  ),
                if (company.employeesCount != null)
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text('${company.employeesCount}'),
                    subtitle: Text(l10n?.employees ?? 'Employees'),
                  ),
                if (company.industry == null && company.employeesCount == null)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No additional details'),
                  ),
                if (metadataAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'ERRORE METADATA: ${metadataAsync.error}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (companyFieldNames.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('company_edit_fields'),
                    dense: true,
                    title: Text(l10n?.customFields ?? 'Custom fields'),
                    trailing: IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: l10n?.editFields ?? 'Edit fields',
                      onPressed: () => showEditFieldsSheet(
                        context,
                        objectType: 'company',
                        metadata: companyMetadata!,
                        candidateFieldNames: companyFieldNames,
                      ),
                    ),
                  ),
                  ...companyFields.map((field) {
                    final value = company.customFields[field.name];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForFieldType(field.type),
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20,
                        ),
                      ),
                      title: Text(value?.toString() ?? 'N/A'),
                      subtitle: Text(field.label ?? field.name),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => CustomFieldEditDialog(
                            entityId: company.id,
                            entityType: 'company',
                            fieldName: field.name,
                            initialValue: value,
                            metadata: field,
                            onSave: (updatedFields) async {
                              await ref.read(companiesProvider.notifier).updateCompany(
                                company.id,
                                customFields: updatedFields,
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          LinkedContactsWidget(
            entityId: company.id,
            type: LinkedContactType.company,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.notes ?? 'Related Notes',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _CompanyNotesList(companyId: company.id),
        ],
      ),
    ),
    );
  }
}

class _CompanyNotesList extends ConsumerWidget {
  final String companyId;
  const _CompanyNotesList({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notesAsync = ref.watch(companyNotesProvider(companyId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(l10n?.noNotesPresent ?? 'No notes present'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          itemBuilder: (context, index) =>
              NoteCard(note: notes[index], companyId: companyId),
        );
      },
      loading: () => const ListSkeleton(shrinkWrap: true),
      error: (err, stack) => Center(child: Text('${l10n?.error ?? 'Error'}: $err')),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Add Note bottom sheet for Company
// ──────────────────────────────────────────────────────────────────────────────
class _AddCompanyNoteSheet extends ConsumerStatefulWidget {
  final String companyId;
  const _AddCompanyNoteSheet({required this.companyId});

  @override
  ConsumerState<_AddCompanyNoteSheet> createState() =>
      _AddCompanyNoteSheetState();
}

class _AddCompanyNoteSheetState extends ConsumerState<_AddCompanyNoteSheet> {
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final text = _bodyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(companyNotesProvider(widget.companyId).notifier)
          .addNote(widget.companyId, text);
      if (mounted) {
        Navigator.of(context).pop();
        SnackbarHelper.showSuccess(context, l10n?.noteSaved ?? 'Note added successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n?.error ?? 'Error'}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n?.newNote ?? 'New Note', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _bodyController,
              enabled: !_isLoading,
              maxLines: 6,
              minLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n?.noteText ?? 'Note text',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.saveNote ?? 'Save Note'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
