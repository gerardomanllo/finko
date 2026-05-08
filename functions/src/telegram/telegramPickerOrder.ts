/**
 * Inline keyboard callbacks use numeric indices; we persist the id order on the
 * session draft so taps resolve to the correct Firestore entity even if the
 * live account/category list changes between render and tap.
 */

export function setPickAccountOrder(draft: Record<string, unknown>, accountIds: string[]): void {
  draft._pickAccountOrder = [...accountIds];
}

export function setPickCategoryOrder(draft: Record<string, unknown>, categoryIds: string[]): void {
  draft._pickCategoryOrder = [...categoryIds];
}

export function setTransferFromOrder(draft: Record<string, unknown>, accountIds: string[]): void {
  draft._transferFromOrder = [...accountIds];
}

export function setTransferToOrder(draft: Record<string, unknown>, accountIds: string[]): void {
  draft._transferToOrder = [...accountIds];
}

export function resolveIdAtIndex(order: unknown, idx: number, fallbackIds: string[]): string | null {
  if (typeof idx !== "number" || !Number.isFinite(idx) || idx < 0) return null;
  if (Array.isArray(order) && order.every((x) => typeof x === "string")) {
    const id = order[idx] as string;
    return id && id.length > 0 ? id : null;
  }
  const id = fallbackIds[idx];
  return id && id.length > 0 ? id : null;
}
