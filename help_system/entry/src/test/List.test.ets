import localUnitTest from './LocalUnit.test';
import accessibilityManagerTest from './AccessibilityManager.test';
import volunteerProfilePageTest from './VolunteerProfilePage.test';
import accessibleButtonTest from './AccessibleButton.test';
import accessibilityIntegrationTest from './AccessibilityIntegration.test';
import accessibilityPerformanceTest from './AccessibilityPerformance.test';

export default function testsuite() {
  localUnitTest();
  accessibilityManagerTest();
  volunteerProfilePageTest();
  accessibleButtonTest();
  accessibilityIntegrationTest();
  accessibilityPerformanceTest();
}