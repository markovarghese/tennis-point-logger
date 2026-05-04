import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import * as SecureStore from 'expo-secure-store';
import { Point } from '../types';
import { pointToSheetRow } from '../utils/csvExport';

WebBrowser.maybeCompleteAuthSession();

// Replace with your Google Cloud OAuth 2.0 client IDs
const ANDROID_CLIENT_ID = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
const IOS_CLIENT_ID     = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
const WEB_CLIENT_ID     = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

const DISCOVERY = {
  authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
  tokenEndpoint:         'https://oauth2.googleapis.com/token',
  revocationEndpoint:    'https://oauth2.googleapis.com/revoke',
};

const SCOPES = [
  'openid',
  'email',
  'profile',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/spreadsheets',
];

const TOKEN_KEY = 'google_access_token';

// ─── Auth ─────────────────────────────────────────────────────────────────────

export function useGoogleAuth() {
  const redirectUri = AuthSession.makeRedirectUri({ scheme: 'tennislogger' });

  const [request, response, promptAsync] = AuthSession.useAuthRequest(
    {
      clientId: WEB_CLIENT_ID,
      androidClientId: ANDROID_CLIENT_ID,
      iosClientId: IOS_CLIENT_ID,
      redirectUri,
      scopes: SCOPES,
      responseType: AuthSession.ResponseType.Token,
    },
    DISCOVERY
  );

  return { request, response, promptAsync };
}

export async function saveToken(token: string): Promise<void> {
  await SecureStore.setItemAsync(TOKEN_KEY, token);
}

export async function getToken(): Promise<string | null> {
  return SecureStore.getItemAsync(TOKEN_KEY);
}

export async function clearToken(): Promise<void> {
  await SecureStore.deleteItemAsync(TOKEN_KEY);
}

// ─── Drive API ────────────────────────────────────────────────────────────────

export async function listDriveFolders(token: string): Promise<{ id: string; name: string }[]> {
  const q = encodeURIComponent("mimeType='application/vnd.google-apps.folder' and trashed=false");
  const res = await fetch(
    `https://www.googleapis.com/drive/v3/files?q=${q}&fields=files(id,name)&orderBy=name`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  const data = await res.json();
  return data.files ?? [];
}

export async function listDriveSheets(token: string): Promise<{ id: string; name: string; modified: string }[]> {
  const q = encodeURIComponent(
    "(mimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or mimeType='application/vnd.google-apps.spreadsheet') and trashed=false"
  );
  const res = await fetch(
    `https://www.googleapis.com/drive/v3/files?q=${q}&fields=files(id,name,modifiedTime)&orderBy=modifiedTime desc`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  const data = await res.json();
  return (data.files ?? []).map((f: { id: string; name: string; modifiedTime: string }) => ({
    id: f.id,
    name: f.name,
    modified: new Date(f.modifiedTime).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
  }));
}

export async function createSheet(token: string, folderId: string, fileName: string): Promise<string> {
  const res = await fetch('https://www.googleapis.com/drive/v3/files', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: fileName,
      mimeType: 'application/vnd.google-apps.spreadsheet',
      parents: [folderId],
    }),
  });
  const data = await res.json();
  return data.id;
}

// ─── Sheets API ───────────────────────────────────────────────────────────────

export async function appendRow(
  token: string,
  spreadsheetId: string,
  point: Point,
  opponent: string
): Promise<void> {
  const row = pointToSheetRow(point, opponent);
  await fetch(
    `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/logger!A:I:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ values: [row] }),
    }
  );
}

export async function appendRows(
  token: string,
  spreadsheetId: string,
  points: Point[],
  opponent: string
): Promise<void> {
  const rows = points.map(p => pointToSheetRow(p, opponent));
  await fetch(
    `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/logger!A:I:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ values: rows }),
    }
  );
}
