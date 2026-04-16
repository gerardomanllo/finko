/// IANA tz database ids for Mexico (four zones) and US (Pacific, Mountain, Eastern).
/// Labels are localized via ARB keys [OnboardingTimezoneOption.labelKey].
class OnboardingTimezoneOption {
  const OnboardingTimezoneOption({
    required this.ianaId,
    required this.labelKey,
  });

  final String ianaId;
  final String labelKey;
}

/// Order: Mexico (Southeast → Northwest), then US Pacific, Mountain, Eastern.
const List<OnboardingTimezoneOption> kOnboardingTimezoneOptions =
    <OnboardingTimezoneOption>[
      OnboardingTimezoneOption(
        ianaId: 'America/Cancun',
        labelKey: 'onboardingTimezoneMexicoSoutheast',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/Mexico_City',
        labelKey: 'onboardingTimezoneMexicoCentral',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/Mazatlan',
        labelKey: 'onboardingTimezoneMexicoPacific',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/Tijuana',
        labelKey: 'onboardingTimezoneMexicoNorthwest',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/Los_Angeles',
        labelKey: 'onboardingTimezoneUsPacific',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/Denver',
        labelKey: 'onboardingTimezoneUsMountain',
      ),
      OnboardingTimezoneOption(
        ianaId: 'America/New_York',
        labelKey: 'onboardingTimezoneUsEastern',
      ),
    ];
