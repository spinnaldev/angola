// import React from 'react';
// import { Link, useLocation } from 'react-router-dom';
// import {
//   HomeIcon,
//   UsersIcon,
//   BriefcaseIcon,
//   ExclamationTriangleIcon,
//   DocumentTextIcon,
//   ChartBarIcon,
//   Cog6ToothIcon,
//   FiMessageCircle,  
// } from '@heroicons/react/24/outline';

// const Sidebar = ({ isOpen, onClose }) => {
//   const location = useLocation();

//   const menuItems = [
//     {
//       name: 'Tableau de bord',
//       path: '/',
//       icon: HomeIcon,
//     },
//     {
//       name: 'Utilisateurs',
//       path: '/users',
//       icon: UsersIcon,
//     },
//     {
//       name: 'Prestataires',
//       path: '/providers',
//       icon: BriefcaseIcon,
//     },
//     {
//       name: 'Projets', // NOUVEAU
//       path: '/projects',
//       icon: DocumentTextIcon,
//     },
//     {
//       name: 'Conversations',  // Nouveau menu
//       href: '/conversations',
//       icon: FiMessageCircle,
//       badge: 'new'  // Badge pour indiquer la nouveauté
//     },
//     {
//       name: 'Litiges',
//       path: '/disputes',
//       icon: ExclamationTriangleIcon,
//     },
//     {
//       name: 'Signalements',
//       path: '/reports',
//       icon: ChartBarIcon,
//     },
//     {
//       name: 'Paramètres',
//       path: '/settings',
//       icon: Cog6ToothIcon,
//     },
//   ];

//   const isActiveRoute = (path) => {
//     if (path === '/') {
//       return location.pathname === '/';
//     }
//     return location.pathname.startsWith(path);
//   };

//   return (
//     <>
//       {/* Overlay pour mobile */}
//       {isOpen && (
//         <div
//           className="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
//           onClick={onClose}
//         />
//       )}

//       {/* Sidebar */}
//       <div
//         className={`fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-200 ease-in-out lg:translate-x-0 lg:static lg:inset-0 ${
//           isOpen ? 'translate-x-0' : '-translate-x-full'
//         }`}
//       >
//         {/* Logo */}
//         <div className="flex items-center justify-center h-16 px-4 border-b border-gray-200">
//           <h1 className="text-xl font-bold text-gray-800">Admin Panel</h1>
//         </div>

//         {/* Navigation */}
//         <nav className="mt-8">
//           <div className="px-4 space-y-2">
//             {menuItems.map((item) => {
//               const Icon = item.icon;
//               const isActive = isActiveRoute(item.path);

//               return (
//                 <Link
//                   key={item.name}
//                   to={item.path}
//                   onClick={onClose}
//                   className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors duration-200 ${
//                     isActive
//                       ? 'bg-blue-50 text-blue-700 border-r-2 border-blue-700'
//                       : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
//                   }`}
//                 >
//                   <Icon
//                     className={`w-5 h-5 mr-3 ${
//                       isActive ? 'text-blue-700' : 'text-gray-400'
//                     }`}
//                   />
//                   {item.name}
//                 </Link>
//               );
//             })}
//           </div>
//         </nav>

//         {/* Informations utilisateur */}
//         <div className="absolute bottom-0 w-full p-4 border-t border-gray-200">
//           <div className="flex items-center">
//             <div className="flex-shrink-0">
//               <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
//                 <span className="text-white text-sm font-medium">A</span>
//               </div>
//             </div>
//             <div className="ml-3">
//               <p className="text-sm font-medium text-gray-700">Administrateur</p>
//               <p className="text-xs text-gray-500">admin@angola.com</p>
//             </div>
//           </div>
//         </div>
//       </div>
//     </>
//   );
// };

// export default Sidebar;
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  FiHome, 
  FiMessageSquare, 
  FiBell,
  FiUsers,
  FiSettings,
  FiBarChart3,
  FiShield
} from 'react-icons/fi';

const Sidebar = () => {
  const location = useLocation();

  const navigation = [
    { name: 'Tableau de bord', href: '/dashboard', icon: FiHome },
    { name: 'Conversations', href: '/conversations', icon: FiMessageSquare },
    { name: 'Notifications', href: '/notifications', icon: FiBell },
    { name: 'Utilisateurs', href: '/users', icon: FiUsers },
    { name: 'Statistiques', href: '/stats', icon: FiBarChart3 },
    { name: 'Modération', href: '/moderation', icon: FiShield },
    { name: 'Paramètres', href: '/settings', icon: FiSettings },
  ];

  const isActive = (href) => {
    if (href === '/dashboard') {
      return location.pathname === '/' || location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(href);
  };

  return (
    <div className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
      <div className="flex flex-col flex-grow pt-5 bg-white border-r border-gray-200 overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4">
          <img
            className="h-8 w-auto"
            src="/logo.png"
            alt="Teyago Admin"
          />
          <span className="ml-2 text-xl font-semibold text-gray-900">
            Teyago Admin
          </span>
        </div>
        
        <div className="mt-8 flex-grow flex flex-col">
          <nav className="flex-1 px-2 space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors ${
                    isActive(item.href)
                      ? 'bg-blue-50 border-r-2 border-blue-600 text-blue-600'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <Icon
                    className={`mr-3 flex-shrink-0 h-5 w-5 ${
                      isActive(item.href)
                        ? 'text-blue-600'
                        : 'text-gray-400 group-hover:text-gray-500'
                    }`}
                  />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
    </div>
  );
};