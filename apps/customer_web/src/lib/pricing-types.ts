/**
 * Strongly typed pricing field and localization contracts for Customer Web.
 * Ensures zero UI logic leak and full TypeScript compiler safety.
 */

export interface LocalizedString {
  ar?: string;
  en?: string;
  [key: string]: string | undefined;
}

export interface DynamicPriceFieldOption {
  id: string;
  label: LocalizedString | string;
}

export interface DynamicPriceField {
  id: string;
  type: 'number' | 'toggle' | 'dropdown' | 'optionsGroup' | 'linearSectors' | string;
  label: LocalizedString | string;
  hint?: LocalizedString;
  unit?: string;
  min?: number;
  max?: number;
  required?: boolean;
  priceModifier?: number;
  description?: LocalizedString;
  displayType?: string;
  options?: DynamicPriceFieldOption[];
}

/**
 * Domain helper function: Resolves field hint/placeholder in a localized,
 * safe manner with automatic fallback to localized label.
 * 
 * No fallback or conditional checks should be written in React components.
 */
export function resolveFieldHint(
  field: DynamicPriceField | null | undefined,
  locale: string = 'ar'
): string {
  if (!field) return '';

  // 1. Check custom hint for requested locale
  if (field.hint) {
    const localizedHint = field.hint[locale]?.trim();
    if (localizedHint) return localizedHint;

    const arabicHint = field.hint.ar?.trim();
    if (arabicHint) return arabicHint;

    const englishHint = field.hint.en?.trim();
    if (englishHint) return englishHint;
  }

  // 2. Fallback to localized label
  if (typeof field.label === 'string') {
    return field.label.trim();
  }

  if (field.label) {
    const localizedLabel = field.label[locale]?.trim();
    if (localizedLabel) return localizedLabel;

    const arabicLabel = field.label.ar?.trim();
    if (arabicLabel) return arabicLabel;

    const englishLabel = field.label.en?.trim();
    if (englishLabel) return englishLabel;
  }

  // 3. Fallback to field id or empty
  return field.id || '';
}
