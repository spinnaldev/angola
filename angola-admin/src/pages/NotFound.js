import React from 'react';
import { Link } from 'react-router-dom';

const NotFound = () => {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-9xl font-bold text-primary">404</h1>
        <h2 className="mt-4 text-3xl font-semibold text-text-primary">
          Page non trouvée
        </h2>
        <p className="mt-2 text-text-secondary">
          La page que vous recherchez n'existe pas ou a été déplacée.
        </p>
        <Link
          to="/dashboard"
          className="btn btn-primary mt-6 inline-block"
        >
          Retour au tableau de bord
        </Link>
      </div>
    </div>
  );
};

export default NotFound;