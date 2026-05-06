# WordPress Patterns

Reference for php-code-simplifier and php-code-quality-reviewer. WordPress-specific idioms, escaping contexts, security patterns, and common bad practices.

---

## Escaping output — context matters

WordPress provides context-specific escaping functions. They are **not interchangeable**. Using the wrong one is a correctness issue, not a style issue.

| Context | Function | Use for |
|---|---|---|
| HTML content | `esc_html()` | Text inside HTML tags: `<p><?php echo esc_html($name); ?></p>` |
| HTML attributes | `esc_attr()` | Attribute values: `<input value="<?php echo esc_attr($value); ?>">` |
| URLs | `esc_url()` | `href`, `src`, `action` attributes |
| JavaScript | `esc_js()` | Values inside `<script>` tags or inline JS |
| Textarea content | `esc_textarea()` | Values inside `<textarea>` |
| SQL | `$wpdb->prepare()` | Database queries — see SQL section |
| Translated strings | `esc_html__()`, `esc_attr__()` | Combined i18n + escaping |

```php
// Bad — no escaping
echo $_GET['search'];
echo $post->post_title;
echo get_option('my_plugin_url');

// Good
echo esc_html(get_the_title());
echo esc_attr($value);
echo esc_url(get_option('my_plugin_url'));

// Bad — wrong escaping context
echo esc_html($url);    // URL sanitisation is different from HTML escaping
echo esc_attr($html);   // strips tags needed in HTML context

// Good — match context to function
echo esc_url($url);
echo wp_kses_post($html);  // allows safe HTML subset
```

---

## SQL via `$wpdb`

```php
// Bad — string interpolation
global $wpdb;
$results = $wpdb->get_results("SELECT * FROM {$wpdb->users} WHERE ID = $user_id");
$wpdb->query("UPDATE {$wpdb->posts} SET post_title = '$title' WHERE ID = $id");

// Good — prepared statements
$results = $wpdb->get_results(
    $wpdb->prepare("SELECT * FROM {$wpdb->users} WHERE ID = %d", $user_id)
);
$wpdb->update(
    $wpdb->posts,
    ['post_title' => $title],
    ['ID' => $id],
    ['%s'],
    ['%d']
);
```

`$wpdb->prepare()` format specifiers:
- `%d` — integer
- `%s` — string (automatically quoted)
- `%f` — float

**Note:** `$wpdb->prepare()` requires at least one format specifier — it will produce a notice if called with no arguments.

---

## Nonces — CSRF protection

Every form submission or AJAX action modifying data must verify a nonce.

```php
// In form output
wp_nonce_field('my_plugin_action', 'my_plugin_nonce');
// Or in URL
$url = wp_nonce_url($base_url, 'my_action');

// In handler — verify before processing
if (!isset($_POST['my_plugin_nonce']) || 
    !wp_verify_nonce($_POST['my_plugin_nonce'], 'my_plugin_action')) {
    wp_die(__('Security check failed', 'my-plugin'));
}

// For AJAX
check_ajax_referer('my_ajax_action', 'nonce');
```

```php
// Bad — no nonce verification
add_action('admin_post_save_settings', function() {
    update_option('my_setting', sanitize_text_field($_POST['value']));
});

// Good
add_action('admin_post_save_settings', function() {
    check_admin_referer('save_settings_action');
    if (!current_user_can('manage_options')) { wp_die('Unauthorised'); }
    update_option('my_setting', sanitize_text_field($_POST['value']));
});
```

---

## Capability checks

```php
// Bad — no capability check
function my_delete_handler() {
    wp_delete_post(intval($_POST['post_id']));
}

// Good — check capability before any sensitive action
function my_delete_handler() {
    if (!current_user_can('delete_posts')) {
        wp_die(__('You do not have permission to delete posts.', 'my-plugin'));
    }
    check_admin_referer('delete_post_' . $_POST['post_id']);
    wp_delete_post(intval($_POST['post_id']));
}
```

Common capabilities:
| Capability | Use for |
|---|---|
| `manage_options` | Plugin settings, options |
| `edit_posts` | Creating/editing content |
| `delete_posts` | Deleting content |
| `manage_categories` | Taxonomy management |
| `upload_files` | Media library |
| Custom capabilities | Use `register_cap()` for plugin-specific permissions |

---

## Input sanitisation

Match the sanitisation function to the data type:

| Data type | Sanitisation function |
|---|---|
| Plain text | `sanitize_text_field()` |
| Textarea | `sanitize_textarea_field()` |
| Email | `sanitize_email()` |
| URL | `esc_url_raw()` (for storage), `esc_url()` (for output) |
| Integer | `absint()` or `intval()` |
| HTML content | `wp_kses_post()` (allowed HTML subset) |
| Filename | `sanitize_file_name()` |
| Key/slug | `sanitize_key()` |

```php
// Bad — unsanitised input saved to database
update_user_meta($user_id, 'phone', $_POST['phone']);

// Good
update_user_meta($user_id, 'phone', sanitize_text_field($_POST['phone']));
```

---

## Global `$wpdb` — acceptable vs not

```php
// Acceptable — WordPress integration adapter, thin layer
class PostRepository {
    public function findBySlug(string $slug): ?array {
        global $wpdb;
        return $wpdb->get_row(
            $wpdb->prepare("SELECT * FROM {$wpdb->posts} WHERE post_name = %s AND post_status = 'publish'", $slug),
            ARRAY_A
        );
    }
}

// Bad — business logic directly uses $wpdb
function calculateRevenue($month) {
    global $wpdb;
    $orders = $wpdb->get_results("SELECT * FROM orders WHERE MONTH(created_at) = $month");
    // ... pricing logic mixed with data access
}
```

Rule: `global $wpdb` belongs in a repository/adapter class, not in domain logic or controllers.

---

## Hooks — action and filter patterns

```php
// Bad — anonymous closure makes unhooking impossible
add_action('save_post', function($post_id) {
    // ...
});

// Good — named function or object method allows remove_action()
add_action('save_post', 'my_plugin_save_post_handler', 10, 2);
add_action('save_post', [$this, 'handleSavePost'], 10, 2);

// Removing a hook
remove_action('save_post', 'my_plugin_save_post_handler', 10);
```

```php
// Bad — modifying global $post directly in filter
add_filter('the_content', function($content) {
    global $post;
    $post->post_title = 'Modified';  // side effect outside filter scope
    return $content . '<p>Extra</p>';
});

// Good — only return modified value
add_filter('the_content', function($content) {
    return $content . '<p>Extra</p>';
});
```

---

## AJAX handlers

```php
// Bad — no nonce, no capability, no auth check
add_action('wp_ajax_my_action', function() {
    $data = $_POST['data'];
    echo json_encode(['result' => process($data)]);
    die();
});

// Good
add_action('wp_ajax_my_action', function() {
    check_ajax_referer('my_action_nonce', 'nonce');
    if (!current_user_can('edit_posts')) {
        wp_send_json_error('Unauthorised', 403);
    }
    $data = sanitize_text_field($_POST['data'] ?? '');
    wp_send_json_success(['result' => process($data)]);
});

// Use wp_send_json_success/error — sets Content-Type and calls wp_die()
```

---

## Options API

```php
// Bad — uncached, no default, no sanitisation on save
$value = get_option('my_option');
update_option('my_option', $_POST['value']);

// Good — with default, sanitised on save, autoloaded off for large data
$value = get_option('my_option', 'default_value');
update_option('my_option', sanitize_text_field($_POST['value']), false); // false = don't autoload
```
