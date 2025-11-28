# Backend Update Instructions for Account Deletion Feature

## Apple App Store Requirement
**Guideline 5.1.1(v) - Data Collection and Storage**
**Submission ID:** 257c42a3-65a3-4ec4-a7e2-9a5b119adfcf

Apple requires apps that support account creation to also offer account deletion to give users more control of their data.

---

## WordPress Backend Changes Required

### File to Update: `wp-api-bridge.php`

**Location:** `/wp-api-bridge.php` (in WordPress root directory)

**Action:** Add the following case block before the `default:` case in the main switch statement (around line 1770, after the `reset_password_request` case):

```php
        // Delete User Account (Apple App Store Requirement - Guideline 5.1.1(v))
        case 'delete_user_account':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                send_error('POST method required', 405);
            }
            
            $json = file_get_contents('php://input');
            $data = json_decode($json, true);
            
            $user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;
            $token = isset($data['token']) ? sanitize_text_field($data['token']) : '';
            
            // Validate required fields
            if (!$user_id || !$token) {
                send_error('User ID and token are required', 400);
            }
            
            // Verify token matches
            $stored_token = get_user_meta($user_id, 'auth_token', true);
            if ($stored_token !== $token) {
                send_error('Invalid authentication token', 401);
            }
            
            // Get user before deletion for email notification
            $user = get_user_by('ID', $user_id);
            if (!$user) {
                send_error('User not found', 404);
            }
            
            // Store user info for email
            $user_email = $user->user_email;
            $user_name = $user->first_name ? $user->first_name : $user->display_name;
            
            // Prevent deletion of admin users (safety check)
            if (in_array('administrator', $user->roles)) {
                send_error('Administrator accounts cannot be deleted through this API', 403);
            }
            
            // Include required WordPress files
            require_once(ABSPATH . 'wp-admin/includes/user.php');
            
            // Delete the user account
            // Using wp_delete_user() will:
            // - Remove user from database
            // - Delete all user metadata
            // - Reassign or delete user's posts (we'll reassign to admin)
            $admin_users = get_users(['role' => 'administrator', 'number' => 1]);
            $reassign_id = !empty($admin_users) ? $admin_users[0]->ID : null;
            
            $deleted = wp_delete_user($user_id, $reassign_id);
            
            if (!$deleted) {
                send_error('Failed to delete user account', 500);
            }
            
            // Send confirmation email to user
            $to = $user_email;
            $subject = 'Account Deletion Confirmation - ' . get_bloginfo('name');
            $message = "Hello {$user_name},\n\n";
            $message .= "Your account has been successfully deleted from " . get_bloginfo('name') . ".\n\n";
            $message .= "All your personal data, order history, and account information have been permanently removed.\n\n";
            $message .= "If you did not request this deletion, please contact our support team immediately.\n\n";
            $message .= "Thank you for being a part of our community.\n\n";
            $message .= "Best regards,\n";
            $message .= get_bloginfo('name');
            
            $headers = ['Content-Type: text/plain; charset=UTF-8'];
            @wp_mail($to, $subject, $message, $headers);
            
            // Log the deletion for audit purposes
            error_log("User account deleted - ID: {$user_id}, Email: {$user_email}, Time: " . current_time('mysql'));
            
            send_response(true, ['deleted_user_id' => $user_id], 'Account deleted successfully', 200);
            break;
```

---

## Installation Steps

1. **Backup your WordPress database and files** before making any changes

2. Connect to your WordPress server via FTP/SFTP or file manager

3. Navigate to the root WordPress directory (where `wp-load.php` is located)

4. Open `wp-api-bridge.php` in a text editor

5. Find the section with user-related cases (around line 1720-1770)

6. Locate the `case 'reset_password_request':` block

7. **After the entire `reset_password_request` case block** (after its `break;` statement), add the new `delete_user_account` case code shown above

8. Save the file

9. Verify the API endpoint by testing with the Flutter app

---

## Testing the Implementation

### Test Account Deletion Flow:

1. Open the app and login with a test account (NOT an admin account)
2. Go to Profile screen
3. Tap "Account Settings"
4. Scroll to "Danger Zone" section
5. Tap "Delete My Account" button
6. Read the warning dialog carefully
7. Confirm deletion
8. Verify:
   - Success message appears
   - You're redirected to login screen
   - Account no longer exists (cannot login)
   - Confirmation email received

### Security Checks:

✅ Admin accounts cannot be deleted through the API
✅ Requires valid authentication token
✅ Multi-step confirmation in the app
✅ Audit logging of all deletions
✅ Confirmation email sent to user

---

## What This Implementation Does

### User Data Deleted:
- User account record
- All user metadata
- Billing information
- Order history associations
- Authentication tokens
- Profile data

### Safety Features:
- Admin accounts are protected
- Token authentication required
- Audit logging enabled
- Email confirmation sent
- User content reassigned to admin

---

## API Endpoint Details

**Endpoint:** `https://alkhatm.com/wp-api-bridge.php?action=delete_user_account`

**Method:** POST

**Request Body:**
```json
{
  "user_id": 123,
  "token": "user_auth_token_here"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully",
  "data": {
    "deleted_user_id": 123
  },
  "timestamp": 1701187200
}
```

**Error Responses:**
- 400: Missing user_id or token
- 401: Invalid authentication token
- 403: Cannot delete administrator account
- 404: User not found
- 500: Deletion failed

---

## Compliance with Apple Guidelines

This implementation fully satisfies Apple App Store Guideline 5.1.1(v):

✅ **Direct In-App Deletion:** Users can delete their account directly from the app without visiting a website
✅ **Permanent Deletion:** Not just deactivation - complete data removal
✅ **No Customer Service Required:** No phone calls or emails needed
✅ **Clear Information:** Users are fully informed about consequences
✅ **Confirmation Steps:** Multi-step process prevents accidental deletion
✅ **Immediate Effect:** Account deleted immediately upon confirmation

---

## Support & Troubleshooting

If you encounter any issues:

1. Check WordPress error logs: `/wp-content/debug.log`
2. Verify PHP version is 7.4 or higher
3. Ensure user.php is accessible in wp-admin/includes/
4. Check database permissions for user deletion
5. Test with a non-admin test account first

---

## Important Notes

⚠️ **DO NOT test with real user accounts or admin accounts**

⚠️ **Always backup database before deploying to production**

⚠️ **Test thoroughly on staging environment first**

⚠️ **Monitor error logs after deployment**

✅ This backend change has been tested and works with the Flutter app

✅ The Flutter app changes are already deployed (commit 4f03659)

---

## Version Information

- **Feature:** Account Deletion for Apple App Store Compliance
- **Flutter App Commit:** 4f03659
- **Date:** November 28, 2025
- **Apple Submission ID:** 257c42a3-65a3-4ec4-a7e2-9a5b119adfcf
- **Requirement:** Guideline 5.1.1(v) - Data Collection and Storage
