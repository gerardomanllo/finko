import '../../../l10n/app_localizations.dart';

/// Maps server `statusLabelKey` / `errorLabelKey` to playful localized copy.
String agentStatusLabel(AppLocalizations l10n, String? key) {
  switch (key) {
    case 'agentStatus.receiving':
      return l10n.agentStatusReceiving;
    case 'agentStatus.readingReceipt':
      return l10n.agentStatusReadingReceipt;
    case 'agentStatus.extractingAmount':
      return l10n.agentStatusExtractingAmount;
    case 'agentStatus.transcribing':
      return l10n.agentStatusTranscribing;
    case 'agentStatus.understanding':
      return l10n.agentStatusUnderstanding;
    case 'agentStatus.thinking':
      return l10n.agentStatusThinking;
    case 'agentStatus.almostThere':
      return l10n.agentStatusAlmostThere;
    case 'agentStatus.loadingCategories':
      return l10n.agentStatusLoadingCategories;
    case 'agentStatus.loadingAccounts':
      return l10n.agentStatusLoadingAccounts;
    case 'agentStatus.saving':
      return l10n.agentStatusSaving;
    default:
      return l10n.agentStatusThinking;
  }
}

String agentErrorLabel(AppLocalizations l10n, String? key) {
  switch (key) {
    case 'agentError.media':
      return l10n.agentErrorMedia;
    case 'agentError.timeout':
      return l10n.agentErrorTimeout;
    case 'agentError.generic':
    default:
      return l10n.agentErrorGeneric;
  }
}
