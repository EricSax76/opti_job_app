// index.js
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { AuthProvider } from './context/AuthContext'; 
import './styles/global.css';

// One-time storage cleanup to avoid stale sessions after schema changes
try {
  const APP_STORAGE_VERSION = '2';
  const current = localStorage.getItem('APP_STORAGE_VERSION');
  if (current !== APP_STORAGE_VERSION) {
    localStorage.removeItem('candidate');
    localStorage.removeItem('empresa');
    localStorage.setItem('APP_STORAGE_VERSION', APP_STORAGE_VERSION);
  }
} catch (_e) {
  // noop
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
    <React.StrictMode>
        <AuthProvider>
            <App />
        </AuthProvider>
    </React.StrictMode>
);
