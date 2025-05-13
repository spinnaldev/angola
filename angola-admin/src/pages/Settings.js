import React, { useState } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { withAuth } from '../context/AuthContext';

// Icônes
import PersonIcon from '@mui/icons-material/Person';
import LockIcon from '@mui/icons-material/Lock';
import NotificationsIcon from '@mui/icons-material/Notifications';
import SettingsIcon from '@mui/icons-material/Settings';
import SecurityIcon from '@mui/icons-material/Security';

const Settings = () => {
  const [activeTab, setActiveTab] = useState('profile');
  const [profileForm, setProfileForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
  });
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [notificationSettings, setNotificationSettings] = useState({
    emailNotifications: true,
    pushNotifications: false,
    newMessages: true,
    newDisputes: true,
    statusUpdates: true,
    marketingEmails: false,
  });
  const [saving, setSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const handleProfileChange = (e) => {
    const { name, value } = e.target;
    setProfileForm((prev) => ({ ...prev, [name]: value }));
  };

  const handlePasswordChange = (e) => {
    const { name, value } = e.target;
    setPasswordForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleNotificationChange = (e) => {
    const { name, checked } = e.target;
    setNotificationSettings((prev) => ({ ...prev, [name]: checked }));
  };

  const handleSaveProfile = (e) => {
    e.preventDefault();
    setSaving(true);
    // Simulation d'une requête API
    setTimeout(() => {
      setSaving(false);
      setSuccessMessage('Profil mis à jour avec succès');
      setTimeout(() => setSuccessMessage(''), 3000);
    }, 1000);
  };

  const handleSavePassword = (e) => {
    e.preventDefault();
    setSaving(true);
    // Simulation d'une requête API
    setTimeout(() => {
      setSaving(false);
      setSuccessMessage('Mot de passe mis à jour avec succès');
      setPasswordForm({
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      });
      setTimeout(() => setSuccessMessage(''), 3000);
    }, 1000);
  };

  const handleSaveNotifications = (e) => {
    e.preventDefault();
    setSaving(true);
    // Simulation d'une requête API
    setTimeout(() => {
      setSaving(false);
      setSuccessMessage('Paramètres de notification mis à jour avec succès');
      setTimeout(() => setSuccessMessage(''), 3000);
    }, 1000);
  };

  const tabs = [
    {
      id: 'profile',
      label: 'Profil',
      icon: PersonIcon,
    },
    {
      id: 'security',
      label: 'Sécurité',
      icon: LockIcon,
    },
    {
      id: 'notifications',
      label: 'Notifications',
      icon: NotificationsIcon,
    },
    {
      id: 'app',
      label: 'Application',
      icon: SettingsIcon,
    },
  ];

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-text-primary">Paramètres</h1>

        {successMessage && (
          <div className="rounded-md bg-success/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <p className="text-sm font-medium text-success">{successMessage}</p>
              </div>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
          {/* Tabs */}
          <div className="md:col-span-1">
            <div className="card p-0">
              <div className="divide-y">
                {tabs.map((tab) => {
                  const Icon = tab.icon;
                  return (
                    <button
                      key={tab.id}
                      className={`flex w-full items-center space-x-3 px-4 py-3 text-left transition-colors ${
                        activeTab === tab.id
                          ? 'bg-primary/10 text-primary'
                          : 'text-text-secondary hover:bg-gray-50'
                      }`}
                      onClick={() => setActiveTab(tab.id)}
                    >
                      <Icon className={`h-5 w-5 ${
                        activeTab === tab.id ? 'text-primary' : 'text-text-disabled'
                      }`} />
                      <span>{tab.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Content */}
          <div className="md:col-span-3">
            <div className="card">
              {/* Profile Settings */}
              {activeTab === 'profile' && (
                <div>
                  <h2 className="mb-6 text-xl font-semibold text-text-primary">
                    Informations du profil
                  </h2>
                  <form onSubmit={handleSaveProfile}>
                    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                      <div>
                        <label htmlFor="firstName" className="label">
                          Prénom
                        </label>
                        <input
                          type="text"
                          id="firstName"
                          name="firstName"
                          className="input w-full"
                          value={profileForm.firstName}
                          onChange={handleProfileChange}
                        />
                      </div>
                      <div>
                        <label htmlFor="lastName" className="label">
                          Nom
                        </label>
                        <input
                          type="text"
                          id="lastName"
                          name="lastName"
                          className="input w-full"
                          value={profileForm.lastName}
                          onChange={handleProfileChange}
                        />
                      </div>
                    </div>

                    <div className="mt-6">
                      <label htmlFor="email" className="label">
                        Adresse e-mail
                      </label>
                      <input
                        type="email"
                        id="email"
                        name="email"
                        className="input w-full"
                        value={profileForm.email}
                        onChange={handleProfileChange}
                      />
                    </div>

                    <div className="mt-6">
                      <label htmlFor="phone" className="label">
                        Téléphone
                      </label>
                      <input
                        type="tel"
                        id="phone"
                        name="phone"
                        className="input w-full"
                        value={profileForm.phone}
                        onChange={handleProfileChange}
                      />
                    </div>

                    <div className="mt-8 flex justify-end">
                      <button
                        type="submit"
                        className="btn btn-primary"
                        disabled={saving}
                      >
                        {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Security Settings */}
              {activeTab === 'security' && (
                <div>
                  <h2 className="mb-6 text-xl font-semibold text-text-primary">
                    Sécurité
                  </h2>
                  <form onSubmit={handleSavePassword}>
                    <div className="mb-6 rounded-lg border p-4">
                      <h3 className="mb-4 flex items-center text-lg font-medium text-text-primary">
                        <LockIcon className="mr-2 h-5 w-5 text-text-secondary" />
                        Changer le mot de passe
                      </h3>
                      <div className="space-y-4">
                        <div>
                          <label htmlFor="currentPassword" className="label">
                            Mot de passe actuel
                          </label>
                          <input
                            type="password"
                            id="currentPassword"
                            name="currentPassword"
                            className="input w-full"
                            value={passwordForm.currentPassword}
                            onChange={handlePasswordChange}
                            required
                          />
                        </div>
                        <div>
                          <label htmlFor="newPassword" className="label">
                            Nouveau mot de passe
                          </label>
                          <input
                            type="password"
                            id="newPassword"
                            name="newPassword"
                            className="input w-full"
                            value={passwordForm.newPassword}
                            onChange={handlePasswordChange}
                            required
                          />
                        </div>
                        <div>
                          <label htmlFor="confirmPassword" className="label">
                            Confirmer le nouveau mot de passe
                          </label>
                          <input
                            type="password"
                            id="confirmPassword"
                            name="confirmPassword"
                            className="input w-full"
                            value={passwordForm.confirmPassword}
                            onChange={handlePasswordChange}
                            required
                          />
                        </div>
                      </div>
                      <div className="mt-4 flex justify-end">
                        <button
                          type="submit"
                          className="btn btn-primary"
                          disabled={saving}
                        >
                          {saving ? 'Enregistrement...' : 'Mettre à jour le mot de passe'}
                        </button>
                      </div>
                    </div>
                  </form>

                  <div className="mt-6 rounded-lg border p-4">
                    <h3 className="mb-4 flex items-center text-lg font-medium text-text-primary">
                      <SecurityIcon className="mr-2 h-5 w-5 text-text-secondary" />
                      Authentification à deux facteurs
                    </h3>
                    <p className="mb-4 text-text-secondary">
                      Renforcez la sécurité de votre compte en activant l'authentification à deux facteurs.
                    </p>
                    <button className="btn btn-outline">Configurer</button>
                  </div>
                </div>
              )}

              {/* Notification Settings */}
              {activeTab === 'notifications' && (
                <div>
                  <h2 className="mb-6 text-xl font-semibold text-text-primary">
                    Paramètres des notifications
                  </h2>
                  <form onSubmit={handleSaveNotifications}>
                    <div className="mb-6 rounded-lg border p-4">
                      <h3 className="mb-4 text-lg font-medium text-text-primary">
                        Préférences globales
                      </h3>
                      <div className="space-y-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="emailNotifications" className="font-medium text-text-primary">
                              Notifications par e-mail
                            </label>
                            <p className="text-sm text-text-secondary">
                              Recevoir des notifications par e-mail
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="emailNotifications"
                              name="emailNotifications"
                              className="peer sr-only"
                              checked={notificationSettings.emailNotifications}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="pushNotifications" className="font-medium text-text-primary">
                              Notifications push
                            </label>
                            <p className="text-sm text-text-secondary">
                              Recevoir des notifications push sur le navigateur
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="pushNotifications"
                              name="pushNotifications"
                              className="peer sr-only"
                              checked={notificationSettings.pushNotifications}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                      </div>
                    </div>

                    <div className="rounded-lg border p-4">
                      <h3 className="mb-4 text-lg font-medium text-text-primary">
                        Types de notifications
                      </h3>
                      <div className="space-y-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="newMessages" className="font-medium text-text-primary">
                              Nouveaux messages
                            </label>
                            <p className="text-sm text-text-secondary">
                              Notifications pour les nouveaux messages
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="newMessages"
                              name="newMessages"
                              className="peer sr-only"
                              checked={notificationSettings.newMessages}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="newDisputes" className="font-medium text-text-primary">
                              Nouveaux litiges
                            </label>
                            <p className="text-sm text-text-secondary">
                              Notifications pour les nouveaux litiges
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="newDisputes"
                              name="newDisputes"
                              className="peer sr-only"
                              checked={notificationSettings.newDisputes}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="statusUpdates" className="font-medium text-text-primary">
                              Mises à jour de statut
                            </label>
                            <p className="text-sm text-text-secondary">
                              Notifications pour les changements de statut des litiges
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="statusUpdates"
                              name="statusUpdates"
                              className="peer sr-only"
                              checked={notificationSettings.statusUpdates}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                        <div className="flex items-center justify-between">
                          <div>
                            <label htmlFor="marketingEmails" className="font-medium text-text-primary">
                              Emails marketing
                            </label>
                            <p className="text-sm text-text-secondary">
                              Recevoir des emails sur les nouveautés et promotions
                            </p>
                          </div>
                          <label className="relative inline-flex cursor-pointer items-center">
                            <input
                              type="checkbox"
                              id="marketingEmails"
                              name="marketingEmails"
                              className="peer sr-only"
                              checked={notificationSettings.marketingEmails}
                              onChange={handleNotificationChange}
                            />
                            <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:ring-4 peer-focus:ring-primary/20"></div>
                          </label>
                        </div>
                      </div>
                      <div className="mt-4 flex justify-end">
                        <button
                          type="submit"
                          className="btn btn-primary"
                          disabled={saving}
                        >
                          {saving ? 'Enregistrement...' : 'Enregistrer les préférences'}
                        </button>
                      </div>
                    </div>
                  </form>
                </div>
              )}

              {/* App Settings */}
              {activeTab === 'app' && (
                <div>
                  <h2 className="mb-6 text-xl font-semibold text-text-primary">
                    Paramètres de l'application
                  </h2>
                  <div className="rounded-lg border p-4">
                    <h3 className="mb-4 text-lg font-medium text-text-primary">
                      Langue et région
                    </h3>
                    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                      <div>
                        <label htmlFor="language" className="label">
                          Langue
                        </label>
                        <select
                          id="language"
                          name="language"
                          className="input w-full"
                          defaultValue="fr"
                        >
                          <option value="fr">Français</option>
                          <option value="en">English</option>
                          <option value="es">Español</option>
                          <option value="pt">Português</option>
                        </select>
                      </div>
                      <div>
                        <label htmlFor="timezone" className="label">
                          Fuseau horaire
                        </label>
                        <select
                          id="timezone"
                          name="timezone"
                          className="input w-full"
                          defaultValue="Europe/Paris"
                        >
                          <option value="Africa/Luanda">Luanda (UTC+01:00)</option>
                          <option value="Africa/Casablanca">Casablanca (UTC+00:00)</option>
                          <option value="Europe/Paris">Paris (UTC+01:00)</option>
                          <option value="America/New_York">New York (UTC-05:00)</option>
                        </select>
                      </div>
                    </div>
                  </div>

                  <div className="mt-6 rounded-lg border p-4">
                    <h3 className="mb-4 text-lg font-medium text-text-primary">
                      Apparence
                    </h3>
                    <div>
                      <label htmlFor="theme" className="label">
                        Thème
                      </label>
                      <div className="mt-2 grid grid-cols-3 gap-4">
                        <div className="flex cursor-pointer flex-col items-center">
                          <div className="mb-2 flex h-20 w-full items-end justify-center rounded-lg bg-white p-2 ring-2 ring-primary">
                            <span className="text-xs">Clair</span>
                          </div>
                          <span className="text-xs text-text-secondary">Clair</span>
                        </div>
                        <div className="flex cursor-pointer flex-col items-center">
                          <div className="mb-2 flex h-20 w-full items-end justify-center rounded-lg bg-gray-800 p-2 text-white">
                            <span className="text-xs">Sombre</span>
                          </div>
                          <span className="text-xs text-text-secondary">Sombre</span>
                        </div>
                        <div className="flex cursor-pointer flex-col items-center">
                          <div className="mb-2 h-20 w-full overflow-hidden rounded-lg">
                            <div className="h-1/2 bg-white"></div>
                            <div className="h-1/2 bg-gray-800"></div>
                          </div>
                          <span className="text-xs text-text-secondary">Système</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="mt-6 rounded-lg border p-4">
                    <h3 className="mb-4 text-lg font-medium text-text-primary">
                      À propos
                    </h3>
                    <div className="space-y-2 text-text-secondary">
                      <p>Version: 1.0.0</p>
                      <p>
                        <a
                          href="#"
                          className="text-primary hover:text-primary-dark"
                        >
                          Conditions d'utilisation
                        </a>
                      </p>
                      <p>
                        <a
                          href="#"
                          className="text-primary hover:text-primary-dark"
                        >
                          Politique de confidentialité
                        </a>
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default withAuth(Settings);