import React, { useState, useEffect } from 'react';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import DashboardLayout from '../layouts/DashboardLayout';
import { dashboardService, userService, disputeService, providerService } from '../services/api';
import { withAuth } from '../context/AuthContext';


// Enregistrer les composants ChartJS
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
);

const StatCard = ({ title, value, icon: Icon, color }) => {
  return (
    <div className="card flex items-center">
      <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${color}`}>
        {typeof Icon === 'function' ? <Icon /> : Icon}
      </div>
      <div className="ml-4">
        <h3 className="text-lg font-medium text-text-secondary">{title}</h3>
        <p className="text-2xl font-bold">{value}</p>
      </div>
    </div>
  );
};

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalProviders: 0,
    totalDisputes: 0,
    newUsersThisMonth: 0,
    recentDisputes: [],
    latestRegistrations: [],
    disputesByStatus: {
      open: 0,
      under_review: 0,
      resolved: 0,
      closed: 0,
    },
    userRegistrationsByMonth: {
      labels: [],
      data: [],
    },
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // En l'absence d'un endpoint spécifique pour les statistiques,
        // nous allons simuler en récupérant les données brutes
        const [usersResponse, providersResponse, disputesResponse] = await Promise.all([
          userService.getAll(1, 100),
          providerService.getAll(1, 100),
          disputeService.getAll(1, 100),
        ]);

        // Formater les données pour le tableau de bord
        const users = usersResponse.data.results || [];
        const providers = providersResponse.data.results || [];
        const disputes = disputesResponse.data.results || [];

        // Statistiques des disputes par statut
        const disputesByStatus = {
          open: disputes.filter(d => d.status === 'open').length,
          under_review: disputes.filter(d => d.status === 'under_review').length,
          resolved: disputes.filter(d => d.status === 'resolved').length,
          closed: disputes.filter(d => d.status === 'closed').length,
        };

        // Inscriptions d'utilisateurs par mois (dernier semestre)
        const today = new Date();
        const labels = [];
        const data = [];

        // Générer les 6 derniers mois
        for (let i = 5; i >= 0; i--) {
          const month = new Date(today.getFullYear(), today.getMonth() - i, 1);
          const monthName = month.toLocaleString('fr-FR', { month: 'short' });
          labels.push(monthName);

          // Compter les utilisateurs inscrits ce mois-ci
          const startDate = new Date(month.getFullYear(), month.getMonth(), 1);
          const endDate = new Date(month.getFullYear(), month.getMonth() + 1, 0);

          const count = users.filter(user => {
            const registrationDate = new Date(user.date_joined);
            return registrationDate >= startDate && registrationDate <= endDate;
          }).length;

          data.push(count);
        }

        setStats({
          totalUsers: users.length,
          totalProviders: providers.length,
          totalDisputes: disputes.length,
          newUsersThisMonth: users.filter(user => {
            const registrationDate = new Date(user.date_joined);
            const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
            return registrationDate >= firstDayOfMonth;
          }).length,
          recentDisputes: disputes.slice(0, 5),
          latestRegistrations: users.slice(0, 5),
          disputesByStatus,
          userRegistrationsByMonth: {
            labels,
            data,
          },
        });
      } catch (error) {
        console.error('Erreur lors du chargement des statistiques', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const userChartData = {
    labels: stats.userRegistrationsByMonth.labels,
    datasets: [
      {
        label: 'Inscriptions',
        data: stats.userRegistrationsByMonth.data,
        fill: true,
        backgroundColor: 'rgba(58, 112, 217, 0.2)',
        borderColor: '#3A70D9',
        tension: 0.3,
      },
    ],
  };

  const disputeChartData = {
    labels: ['En attente', 'En examen', 'Résolu', 'Fermé'],
    datasets: [
      {
        data: [
          stats.disputesByStatus.open,
          stats.disputesByStatus.under_review,
          stats.disputesByStatus.resolved,
          stats.disputesByStatus.closed,
        ],
        backgroundColor: [
          '#FF8A30', // orange for open
          '#FFC107', // yellow for under_review
          '#4CAF50', // green for resolved
          '#9EA5B8', // gray for closed
        ],
        borderWidth: 0,
      },
    ],
  };

  const chartOptions = {
    plugins: {
      legend: {
        position: 'bottom',
      },
    },
    maintainAspectRatio: false,
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement des statistiques...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Statistiques */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Utilisateurs"
            value={stats.totalUsers}
            icon={function UserIcon() {
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
              </svg>
            }}
            color="bg-primary"
          />
          <StatCard
            title="Prestataires"
            value={stats.totalProviders}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z" />
              </svg>
            )}
            color="bg-secondary"
          />
          <StatCard
            title="Litiges"
            value={stats.totalDisputes}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 12.75c1.148 0 2.278.08 3.383.237 1.037.146 1.866.966 1.866 2.013 0 3.728-2.35 6.75-5.25 6.75S6.75 18.728 6.75 15c0-1.046.83-1.867 1.866-2.013A24.204 24.204 0 0112 12.75zm0 0c2.883 0 5.647.508 8.207 1.44a23.91 23.91 0 01-1.152 6.06M12 12.75c-2.883 0-5.647.508-8.208 1.44.125 2.104.52 4.136 1.153 6.06M12 12.75a2.25 2.25 0 002.248-2.354M12 12.75a2.25 2.25 0 01-2.248-2.354M12 8.25c.995 0 1.971-.08 2.922-.236.403-.066.74-.358.795-.762a3.778 3.778 0 00-.399-2.25M12 8.25c-.995 0-1.97-.08-2.922-.236-.402-.066-.74-.358-.795-.762a3.734 3.734 0 01.4-2.253M12 8.25a2.25 2.25 0 00-2.248 2.146M12 8.25a2.25 2.25 0 012.248 2.146M8.683 5a6.032 6.032 0 01-1.155-1.002c.07-.63.27-1.222.574-1.747m.581 2.749A3.75 3.75 0 0115.318 5m0 0c.427-.283.815-.62 1.155-.999a4.471 4.471 0 00-.575-1.752M4.921 6a24.048 24.048 0 00-.392 3.314c1.668.546 3.416.914 5.223 1.082M19.08 6c.205 1.08.337 2.187.392 3.314a23.882 23.882 0 01-5.223 1.082" />
              </svg>
            )}
            color="bg-error"
          />
          <StatCard
            title="Nouveaux ce mois"
            value={stats.newUsersThisMonth}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5m-9-6h.008v.008H12v-.008zM12 15h.008v.008H12V15zm0 2.25h.008v.008H12v-.008zM9.75 15h.008v.008H9.75V15zm0 2.25h.008v.008H9.75v-.008zM7.5 15h.008v.008H7.5V15zm0 2.25h.008v.008H7.5v-.008zm6.75-4.5h.008v.008h-.008v-.008zm0 2.25h.008v.008h-.008V15zm0 2.25h.008v.008h-.008v-.008zm2.25-4.5h.008v.008H16.5v-.008zm0 2.25h.008v.008H16.5V15z" />
              </svg>
            )}
            color="bg-accent"
          />
        </div>

        {/* Graphiques */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="card">
            <h3 className="mb-4 text-lg font-semibold text-text-primary">
              Inscriptions des utilisateurs (6 derniers mois)
            </h3>
            <div className="h-72">
              <Line data={userChartData} options={chartOptions} />
            </div>
          </div>

          <div className="card">
            <h3 className="mb-4 text-lg font-semibold text-text-primary">
              Répartition des litiges par statut
            </h3>
            <div className="h-72">
              <Doughnut data={disputeChartData} options={chartOptions} />
            </div>
          </div>
        </div>

        {/* Derniers litiges et inscriptions */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="card">
            <h3 className="mb-4 text-lg font-semibold text-text-primary">
              Litiges récents
            </h3>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Titre
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Client
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Statut
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Date
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {stats.recentDisputes.map((dispute) => (
                    <tr key={dispute.id}>
                      <td className="whitespace-nowrap py-2 text-sm text-text-primary">
                        {dispute.title}
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm text-text-secondary">
                        {dispute.client_name}
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm">
                        <span
                          className={`badge ${
                            dispute.status === 'open'
                              ? 'badge-warning'
                              : dispute.status === 'under_review'
                              ? 'badge-info'
                              : dispute.status === 'resolved'
                              ? 'badge-success'
                              : 'badge-secondary'
                          }`}
                        >
                          {dispute.status === 'open'
                            ? 'Ouvert'
                            : dispute.status === 'under_review'
                            ? 'En examen'
                            : dispute.status === 'resolved'
                            ? 'Résolu'
                            : 'Fermé'}
                        </span>
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm text-text-secondary">
                        {new Date(dispute.created_at).toLocaleDateString('fr-FR')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="card">
            <h3 className="mb-4 text-lg font-semibold text-text-primary">
              Nouveaux utilisateurs
            </h3>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Nom
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Email
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Rôle
                    </th>
                    <th className="py-3 text-left text-xs font-medium uppercase tracking-wider text-text-secondary">
                      Date
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {stats.latestRegistrations.map((user) => (
                    <tr key={user.id}>
                      <td className="whitespace-nowrap py-2 text-sm text-text-primary">
                        {user.first_name ? `${user.first_name} ${user.last_name}` : user.username}
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm text-text-secondary">
                        {user.email}
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm">
                        <span
                          className={`badge ${
                            user.role === 'admin'
                              ? 'badge-info'
                              : user.role === 'provider'
                              ? 'badge-success'
                              : 'badge-secondary'
                          }`}
                        >
                          {user.role === 'admin'
                            ? 'Admin'
                            : user.role === 'provider'
                            ? 'Prestataire'
                            : 'Client'}
                        </span>
                      </td>
                      <td className="whitespace-nowrap py-2 text-sm text-text-secondary">
                        {new Date(user.date_joined).toLocaleDateString('fr-FR')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default withAuth(Dashboard);