import localUnitTest from './LocalUnit.test';
import accessibilityManagerTest from './AccessibilityManager.test';
import accessibilityThemeTest from './AccessibilityTheme.test';
import volunteerProfilePageTest from './VolunteerProfilePage.test';
import accessibleButtonTest from './AccessibleButton.test';
import accessibilityIntegrationTest from './AccessibilityIntegration.test';
import accessibilityPerformanceTest from './AccessibilityPerformance.test';
import watchLoginFormHelperTest from './WatchLoginFormHelper.test';

export default function testsuite() {
  localUnitTest();
  accessibilityManagerTest();
  accessibilityThemeTest();
  volunteerProfilePageTest();
  accessibleButtonTest();
  accessibilityIntegrationTest();
  accessibilityPerformanceTest();
  watchLoginFormHelperTest();
}
