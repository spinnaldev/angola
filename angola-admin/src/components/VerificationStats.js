// src/components/VerificationStats.js
import React from 'react';

const VerificationStats = ({ statistics, loading = false, compact = false }) => {
  if (loading) {
    return (
      <div className={`grid grid-cols-1 gap-4 ${compact ? 'sm:grid-cols-2' : 'sm:grid-cols-4'} mb-6`}>
        {[...Array(4)].map((_, index) => (
          <div key={index} className="bg-white overflow-hidden shadow rounded-lg animate-pulse">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-gray-200 rounded"></div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <div className="h-4 bg-gray-200 rounded mb-2"></div>
                  <div className="h-6 bg-gray-200 rounded"></div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  const statsConfig = [
    {
      key: 'total',
      label: 'Total',
      value: statistics.total || 0,
      icon: '📊',
      color: 'text-gray-900',
      bgColor: 'bg-gray-50'
    },
    {
      key: 'pending',
      label: 'En attente',
      value: statistics.pending || 0,
      icon: '⏳',
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-50'
    },
    {
      key: 'verified',
      label: 'Vérifiés',
      value: statistics.verified || 0,
      icon: '✅',
      color: 'text-green-600',
      bgColor: 'bg-green-50'
    },
    {
      key: 'rejected',
      label: 'Rejetés',
      value: statistics.rejected || 0,
      icon: '❌',
      color: 'text-red-600',
      bgColor: 'bg-red-50'
    }
  ];

  return (
    <div className={`grid grid-cols-1 gap-4 ${compact ? 'sm:grid-cols-2' : 'sm:grid-cols-4'} mb-6`}>
      {statsConfig.map((stat) => (
        <div key={stat.key} className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className={`w-10 h-10 ${stat.bgColor} rounded-lg flex items-center justify-center`}>
                  <span className="text-2xl">{stat.icon}</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    {stat.label}
                  </dt>
                  <dd className={`text-lg font-medium ${stat.color}`}>
                    {stat.value.toLocaleString()}
                  </dd>
                  {!compact && statistics.total > 0 && (
                    <dd className="text-xs text-gray-400">
                      {((stat.value / statistics.total) * 100).toFixed(1)}%
                    </dd>
                  )}
                </dl>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default VerificationStats;