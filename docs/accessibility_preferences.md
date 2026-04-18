# Accessibility Preferences

Base path: `/api/v1`

Accessibility preferences are stored per user in `users.settings["accessibility"]`.

Current backend scope:
- larger text presets
- higher contrast mode
- reading font preference
- reduced motion preference

The backend returns normalized defaults even when the user has never saved accessibility settings before.

## Supported fields

```json
{
  "accessibility": {
    "font_scale": "md",
    "contrast_mode": "default",
    "reading_font": "default",
    "reduce_motion": false
  }
}
```

Allowed values:
- `font_scale`: `sm | md | lg | xl`
- `contrast_mode`: `default | high`
- `reading_font`: `default | dyslexic`
- `reduce_motion`: `true | false`

## `GET /profile`

Returns the current user's profile plus normalized accessibility preferences.

Example response:

```json
{
  "user": {
    "id": 7,
    "email": "teacher@example.com",
    "first_name": "Ana",
    "last_name": "Trajkovska",
    "locale": "mk",
    "active": true
  },
  "roles": ["teacher"],
  "teacher_profile": {
    "id": 3,
    "school_id": 1,
    "title": "Наставник",
    "bio": "Математика",
    "room_name": "Кабинет 12",
    "room_label": "К12"
  },
  "student_profile": null,
  "accessibility": {
    "font_scale": "lg",
    "contrast_mode": "high",
    "reading_font": "dyslexic",
    "reduce_motion": true
  }
}
```

## `PATCH /profile`

Accepts partial accessibility updates together with the existing profile fields.

Example request:

```json
{
  "first_name": "Ana",
  "accessibility": {
    "font_scale": "lg",
    "contrast_mode": "high"
  }
}
```

Example success response:

```json
{
  "user": {
    "id": 7,
    "email": "teacher@example.com",
    "first_name": "Ana",
    "last_name": "Trajkovska",
    "locale": "mk",
    "active": true
  },
  "teacher_profile": {
    "id": 3,
    "school_id": 1,
    "title": "Наставник",
    "bio": "Математика",
    "room_name": "Кабинет 12",
    "room_label": "К12"
  },
  "student_profile": null,
  "accessibility": {
    "font_scale": "lg",
    "contrast_mode": "high",
    "reading_font": "default",
    "reduce_motion": false
  }
}
```

Notes:
- partial updates only change the provided keys
- omitted keys keep their previous values
- users can return to defaults by sending the default values explicitly
- invalid values return `422 Unprocessable Entity`
