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
import { dashboardService } from '../services/api';
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

const StatCard = ({ title, value, icon: Icon, color, change }) => {
  return (
    <div className="bg-white rounded-lg shadow-sm p-5 hover:shadow-md transition-shadow">
      <div className="flex items-center">
        <div className={`flex h-12 w-12 items-center justify-center rounded-lg text-white ${color} shrink-0`}>
          {typeof Icon === 'function' ? <Icon /> : Icon}
        </div>
        <div className="ml-4 flex-1 min-w-0">
          <h3 className="text-xs font-medium text-gray-500 uppercase tracking-wide">{title}</h3>
          <div className="flex items-baseline mt-1">
            <p className="text-2xl font-bold text-gray-900">{value}</p>
            {change !== undefined && change !== null && (
              <p className={`ml-2 text-xs font-medium ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                {change > 0 ? '+' : ''}{change} ce mois
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

const Dashboard = () => {
  const [stats, setStats] = useState({
    totals: {
      users: 0,
      providers: 0,
      projects: 0,
      disputes: 0
    },
    this_month: {
      new_users: 0,
      active_projects: 0,
      open_disputes: 0,
      revenue: 0
    },
    user_registrations: [],
    project_stats: {
      total_projects: 0,
      by_status: { open: 0, in_progress: 0 },
      monthly_stats: [],
      top_categories: []
    },
    recent_activity: {
      projects: [],
      disputes: []
    }
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // Récupérer les statistiques générales et projets en parallèle
        const [dashboardResponse, projectResponse] = await Promise.all([
          dashboardService.getStats(),
          dashboardService.getProjectStats(),
        ]);

        const dashboardData = dashboardResponse.data;
        const projectData = projectResponse.data;

        setStats({
          totals: dashboardData.totals,
          this_month: dashboardData.this_month,
          user_registrations: dashboardData.user_registrations,
          project_stats: projectData,
          recent_activity: dashboardData.recent_activity
        });

      } catch (error) {
        console.error('Erreur lors du chargement des statistiques', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Graphique des inscriptions utilisateurs
  const userChartData = {
    labels: stats.user_registrations.map(item => {
      const date = new Date(item.month + '-01');
      return date.toLocaleDateString('fr-FR', { month: 'short', year: 'numeric' });
    }),
    datasets: [
      {
        label: 'Nouvelles inscriptions',
        data: stats.user_registrations.map(item => item.count),
        fill: true,
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        borderColor: 'rgb(59, 130, 246)',
        tension: 0.3,
      },
    ],
  };

  // Graphique des projets par mois
  const projectChartData = {
    labels: stats.project_stats.monthly_stats.map(item => {
      const date = new Date(item.month + '-01');
      return date.toLocaleDateString('fr-FR', { month: 'short', year: 'numeric' });
    }),
    datasets: [
      {
        label: 'Nouveaux projets',
        data: stats.project_stats.monthly_stats.map(item => item.count),
        backgroundColor: 'rgba(34, 197, 94, 0.8)',
        borderColor: 'rgb(34, 197, 94)',
        borderWidth: 1,
      },
    ],
  };

  // Graphique des catégories populaires
  const categoryChartData = {
    labels: stats.project_stats.top_categories.map(cat => cat.category__name),
    datasets: [
      {
        data: stats.project_stats.top_categories.map(cat => cat.count),
        backgroundColor: [
          '#3B82F6', // blue
          '#10B981', // green
          '#F59E0B', // yellow
          '#EF4444', // red
          '#8B5CF6', // purple
        ],
        borderWidth: 0,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
        labels: {
          padding: 15,
          usePointStyle: true,
          font: {
            size: 12
          }
        }
      },
      tooltip: {
        titleFont: {
          size: 13
        },
        bodyFont: {
          size: 12
        },
        padding: 12
      }
    },
    scales: {
      x: {
        grid: {
          display: false
        },
        ticks: {
          font: {
            size: 11
          }
        }
      },
      y: {
        grid: {
          color: 'rgba(0, 0, 0, 0.05)'
        },
        ticks: {
          font: {
            size: 11
          }
        }
      }
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Chargement des statistiques...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="px-6 py-6 space-y-8">
        {/* En-tête */}
        <div className="mb-2">
          <h1 className="text-2xl font-bold text-gray-900">Tableau de Bord</h1>
          <p className="mt-1 text-sm text-gray-600">Vue d'ensemble de votre plateforme</p>
        </div>

        {/* Statistiques principales - Grid avec plus d'espace */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
          <StatCard
            title="Total Utilisateurs"
            value={stats.totals.users}
            change={stats.this_month.new_users}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
              </svg>
            )}
            color="bg-blue-600"
          />
          
          <StatCard
            title="Prestataires"
            value={stats.totals.providers}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z" />
              </svg>
            )}
            color="bg-green-600"
          />

          <StatCard
            title="Litiges Ouverts"
            value={stats.totals.disputes}
            change={stats.this_month.open_disputes}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
              </svg>
            )}
            color="bg-red-600"
          />

          <StatCard
            title="Total Projets"
            value={stats.project_stats.total_projects}
            change={stats.this_month.active_projects}
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
              </svg>
            )}
            color="bg-purple-600"
          />

          <StatCard
            title="Projets Ouverts"
            value={stats.project_stats.by_status.open}
            color="bg-orange-500"
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 10.5V6.75a4.5 4.5 0 119 0v3.75M3.75 21.75h16.5c.621 0 1.125-.504 1.125-1.125v-9.75c0-.621-.504-1.125-1.125-1.125H3.75c-.621 0-1.125.504-1.125 1.125v9.75c0 .621.504 1.125 1.125 1.125z" />
              </svg>
            )}
          />
          
          <StatCard
            title="En Cours"
            value={stats.project_stats.by_status.in_progress}
            color="bg-blue-500"
            icon={() => (
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            )}
          />
        </div>

        {/* Graphiques - Plus d'espace */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Évolution des inscriptions */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Évolution des inscriptions</h3>
            <div className="h-64">
              <Line data={userChartData} options={chartOptions} />
            </div>
          </div>

          {/* Nouveaux projets par mois */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Nouveaux projets par mois</h3>
            <div className="h-64">
              <Bar data={projectChartData} options={chartOptions} />
            </div>
          </div>
        </div>

        {/* Catégories populaires et activité récente */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Catégories populaires */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Catégories</h3>
            <div className="h-64 flex items-center justify-center">
              <div className="w-full max-w-sm">
                <Doughnut data={categoryChartData} options={chartOptions} />
              </div>
            </div>
          </div>

          {/* Activité récente */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Projets Récents</h3>
            <div className="space-y-3 max-h-64 overflow-y-auto">
              {stats.recent_activity.projects.length > 0 ? (
                stats.recent_activity.projects.slice(0, 5).map((project) => (
                  <div key={project.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-gray-900 truncate">{project.title}</p>
                      <p className="text-xs text-gray-600 mt-1">Par {project.client_name}</p>
                    </div>
                    <div className="text-right ml-4 flex-shrink-0">
                      <span className={`inline-flex px-2.5 py-1 text-xs font-semibold rounded-full ${
                        project.status === 'open' 
                          ? 'bg-green-100 text-green-800'
                          : project.status === 'in_progress'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {project.status === 'open' ? 'Ouvert' : project.status === 'in_progress' ? 'En cours' : project.status}
                      </span>
                      <p className="text-xs text-gray-500 mt-1">
                        {new Date(project.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' })}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-12">
                  <span className="text-4xl mb-2 block">📋</span>
                  <p className="text-gray-500 text-sm">Aucun projet récent</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default withAuth(Dashboard);