# Role Profile Edit Flow Design

**Date:** 2026-05-14

**Scope**
- Unify the three role-specific personal centers around the same interaction model for profile editing.
- Replace inline profile editing with navigation to dedicated edit pages.
- Cover:
  - `help-seeker/ProfilePage.ets` + `SeekerPersonalCenterPane.ets`
  - `volunteer/ProfilePage.ets` + `VolunteerProfileEditPage.ets`
  - `community/ProfilePage.ets`
- Reuse the existing user profile update API and volunteer skill API.

**Problem**
- Volunteer users already edit profile information through a dedicated page, which creates a clear "view profile -> enter edit page -> save -> return" flow.
- Community users currently edit inside the personal center page, so the page mixes display, navigation, settings, and form responsibilities.
- Help-seeker users currently do not have the same dedicated edit-page experience.
- The result is inconsistent product behavior across roles for a common task.

**Goals**
- Make all three roles use the same edit-entry pattern.
- Keep profile pages focused on display and navigation, not inline form editing.
- Reuse the existing backend update path where possible.
- Keep this change small enough to implement without broad schema work.

**Non-Goals**
- Do not redesign unrelated personal-center visuals.
- Do not change login-account modification rules.
- Do not introduce new backend schema fields in this round.
- Do not merge all three role edit pages into one generic page in this round.

**Chosen Direction**
- Standardize on the volunteer interaction model: enter a dedicated profile edit page from the personal center, save, then return.
- Keep separate edit pages per role, but align their structure, validation, and save flow.
- Explicitly avoid adding new help-seeker-specific backend fields in this round. Help-seeker editing will cover only the shared base profile fields.

**User Experience**
- Volunteer:
  - Keep the existing dedicated edit page entry from the profile card.
  - Preserve volunteer-only skill editing on that page.
- Community:
  - Remove inline editing from the personal center page.
  - Add navigation from the personal center into a new dedicated community profile edit page.
- Help-seeker:
  - Add an "edit profile" entry to the personal center.
  - Navigate into a new dedicated help-seeker profile edit page.

**Field Rules**
- Shared editable fields for all three roles:
  - `name`
  - `address`
  - `emergencyContact`
  - `emergencyPhone`
- Shared read-only field:
  - `phone`
- Volunteer-only editable field:
  - `skills`
- Not edited in this round:
  - `disabilities`
  - `certifications`
  - `age`
  - `gender`
  - `avatar`
  - `role`

**Validation Rules**
- `name` is required.
- `emergencyPhone` is optional, but if filled in it must pass the current lightweight length-based validation already used in existing pages.
- `phone` is displayed but disabled.
- Save buttons are disabled while a save request is in flight.

**Navigation Flow**
- Entering an edit page always fetches the latest profile with `UserApi.getCurrentProfile()`.
- Saving base profile data uses `UserApi.updateUserProfile(...)`.
- Volunteer skill changes continue to use `UserApi.updateMyVolunteerSkills(...)` after the base profile save succeeds.
- On successful save:
  - write the returned profile to `StorageUtil`
  - return with `router.back()`
  - trigger a profile refresh when the personal center becomes visible again
- If the API indicates login expiry, redirect through the existing logout + login-page path.

**Page Responsibilities**
- Personal center pages should only own:
  - profile summary display
  - navigation entries
  - accessibility settings toggle
  - logout flow
- Dedicated edit pages should own:
  - form state
  - validation
  - save requests
  - save/loading feedback

**Implementation Shape**
- Keep `pages/volunteer/VolunteerProfileEditPage.ets` as the reference behavior.
- Add:
  - `pages/help-seeker/HelpSeekerProfileEditPage.ets`
  - `pages/community/CommunityProfileEditPage.ets`
- Update personal center entry points so each role navigates to its dedicated edit page.
- Remove the inline community edit form and its related state from `pages/community/ProfilePage.ets`.
- Register the new pages in `resources/base/profile/main_pages.json`.

**Files In Scope**
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\SeekerPersonalCenterPane.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\HelpSeekerProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\volunteer\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\volunteer\VolunteerProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\CommunityProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\resources\base\profile\main_pages.json`
- Relevant tests under `C:\Users\22789\Desktop\endProject\help_system\entry\src\test\`

**Testing**
- Verify each role can enter its edit page from the personal center.
- Verify shared fields load correctly from the latest server profile.
- Verify save success updates the display after navigating back.
- Verify volunteer skill loading, toggling, and saving still work.
- Verify the community page no longer renders an inline edit form.
- Run a front-end compile/build verification command after implementation.

**Risks**
- The community profile page currently mixes several concerns, so removing inline state may require careful cleanup to avoid dead code.
- New page registration in `main_pages.json` is easy to miss and would break navigation at runtime.
- If tests encode old community inline-edit behavior, they will need intentional updates.

**Future Follow-Up**
- If product requirements later need help-seeker-specific editable care notes or disability detail editing, add that in a separate change with explicit backend model and storage decisions.
- If the three edit pages remain highly similar after this change, a later refactor can extract shared form builders or helpers.

**Self-Review**
- No placeholders remain.
- The scope is intentionally limited to interaction unification and shared base profile editing.
- The help-seeker field question is resolved explicitly: no new backend field is added in this round.
- The implementation path stays consistent with the user's preference for dedicated edit pages instead of inline forms.
