/**
 * Same env pattern as customer app (`new_balan_apk`): `.env` / `EXPO_PUBLIC_*` / `VITE_*` fallbacks.
 */
const appJson = require('./app.json');

function stripTrailingSlash(s) {
  return String(s).replace(/\/$/, '');
}

const apiOrigin = stripTrailingSlash(
  process.env.EXPO_PUBLIC_API_ORIGIN ||
    process.env.EXPO_PUBLIC_ENVIRONMENT ||
    process.env.VITE_API_BASE_URL ||
    'http://127.0.0.1:8000',
);

let apiPrefix = process.env.EXPO_PUBLIC_API_PREFIX || process.env.VITE_API_PREFIX || '/api/v1';
if (!apiPrefix.startsWith('/')) {
  apiPrefix = `/${apiPrefix}`;
}

/** Set after `eas init` / `eas build:configure` for this app — optional for local `expo run:android`. */
const easProjectId = process.env.EAS_PROJECT_ID || '';

module.exports = {
  expo: {
    ...appJson.expo,
    android: {
      ...(appJson.expo.android || {}),
      /** Allow http:// to LAN / emulator during local dev (required for many Android builds). */
      usesCleartextTraffic: true,
    },
    extra: {
      ...(appJson.expo.extra || {}),
      apiOrigin,
      apiPrefix,
      eas: {
        ...(appJson.expo.extra && appJson.expo.extra.eas ? appJson.expo.extra.eas : {}),
        ...(easProjectId ? { projectId: easProjectId } : {}),
      },
    },
  },
};
