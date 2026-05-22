/** Stable keys for client l10n (`agentStatus.*`, `agentError.*`). */
export const AgentStatusKeys = {
  receiving: "agentStatus.receiving",
  readingReceipt: "agentStatus.readingReceipt",
  extractingAmount: "agentStatus.extractingAmount",
  transcribing: "agentStatus.transcribing",
  understanding: "agentStatus.understanding",
  thinking: "agentStatus.thinking",
  almostThere: "agentStatus.almostThere",
  loadingCategories: "agentStatus.loadingCategories",
  loadingAccounts: "agentStatus.loadingAccounts",
  saving: "agentStatus.saving",
} as const;

export const AgentErrorKeys = {
  generic: "agentError.generic",
  media: "agentError.media",
  timeout: "agentError.timeout",
} as const;
