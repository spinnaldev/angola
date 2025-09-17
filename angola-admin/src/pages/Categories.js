import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { withAuth } from '../context/AuthContext';
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

const CategoryModal = ({ category, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    name: category?.name || '',
    description: category?.description || '',
    icon: category?.icon || '',
    image_url: category?.image_url || '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              {category ? 'Modifier la catégorie' : 'Ajouter une catégorie'}
            </h3>
            <button
              className="text-gray-400 hover:text-gray-600"
              onClick={onCancel}
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <form onSubmit={handleSubmit}>
            <div className="px-6 py-4">
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Nom *
                  </label>
                  <input
                    type="text"
                    name="name"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.name}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <textarea
                    name="description"
                    rows="3"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.description}
                    onChange={handleChange}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Icône (classe CSS)
                  </label>
                  <input
                    type="text"
                    name="icon"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.icon}
                    onChange={handleChange}
                    placeholder="Ex: home, person, etc."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    URL de l'image
                  </label>
                  <input
                    type="url"
                    name="image_url"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.image_url}
                    onChange={handleChange}
                    placeholder="https://example.com/image.jpg"
                  />
                </div>
              </div>
            </div>

            <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end space-x-3">
              <button
                type="button"
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                onClick={onCancel}
              >
                Annuler
              </button>
              <button
                type="submit"
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Enregistrer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

const SubcategoryModal = ({ subcategory, categories, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    name: subcategory?.name || '',
    description: subcategory?.description || '',
    icon: subcategory?.icon || '',
    category: subcategory?.category?.id || (categories.length > 0 ? categories[0].id : ''),
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              {subcategory ? 'Modifier la sous-catégorie' : 'Ajouter une sous-catégorie'}
            </h3>
            <button
              className="text-gray-400 hover:text-gray-600"
              onClick={onCancel}
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <form onSubmit={handleSubmit}>
            <div className="px-6 py-4">
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Catégorie parente *
                  </label>
                  <select
                    name="category"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.category}
                    onChange={handleChange}
                    required
                  >
                    {categories.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Nom *
                  </label>
                  <input
                    type="text"
                    name="name"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.name}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <textarea
                    name="description"
                    rows="3"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.description}
                    onChange={handleChange}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Icône (classe CSS)
                  </label>
                  <input
                    type="text"
                    name="icon"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    value={formData.icon}
                    onChange={handleChange}
                    placeholder="Ex: home, person, etc."
                  />
                </div>
              </div>
            </div>

            <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end space-x-3">
              <button
                type="button"
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                onClick={onCancel}
              >
                Annuler
              </button>
              <button
                type="submit"
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Enregistrer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

const DeleteConfirmationModal = ({ item, itemType, onConfirm, onCancel }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="px-6 py-4">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-lg font-medium text-gray-900">
                  Confirmer la suppression
                </h3>
                <div className="mt-2">
                  <p className="text-sm text-gray-500">
                    Êtes-vous sûr de vouloir supprimer {itemType === 'category' ? 'la catégorie' : 'la sous-catégorie'}{' '}
                    <span className="font-medium text-gray-900">"{item.name}"</span> ?
                    {itemType === 'category' && (
                      <span className="block mt-2 text-red-600 font-medium">
                        ⚠️ Attention: Toutes les sous-catégories associées seront également supprimées.
                      </span>
                    )}
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end space-x-3">
            <button
              type="button"
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              onClick={onCancel}
            >
              Annuler
            </button>
            <button
              type="button"
              className="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              onClick={() => onConfirm(item)}
            >
              Supprimer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const Categories = () => {
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [expandedCategory, setExpandedCategory] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [subcategoryModalOpen, setSubcategoryModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [currentItem, setCurrentItem] = useState(null);
  const [deleteType, setDeleteType] = useState(null);

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const [categoriesResponse, subcategoriesResponse] = await Promise.all([
        axios.get(`${API_URL}/categories/`),
        axios.get(`${API_URL}/subcategories/`),
      ]);

      setCategories(categoriesResponse.data.results || categoriesResponse.data);
      setSubcategories(subcategoriesResponse.data.results || subcategoriesResponse.data);
    } catch (err) {
      console.error('Erreur lors du chargement des catégories', err);
      setError('Impossible de charger les catégories. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const toggleCategory = (categoryId) => {
    setExpandedCategory(expandedCategory === categoryId ? null : categoryId);
  };

  const handleAddCategory = () => {
    setCurrentItem(null);
    setCategoryModalOpen(true);
  };

  const handleEditCategory = (category) => {
    setCurrentItem(category);
    setCategoryModalOpen(true);
  };

  const handleAddSubcategory = () => {
    setCurrentItem(null);
    setSubcategoryModalOpen(true);
  };

  const handleEditSubcategory = (subcategory) => {
    const category = categories.find(cat => cat.id === subcategory.category);
    setCurrentItem({ ...subcategory, category });
    setSubcategoryModalOpen(true);
  };

  const handleDeleteCategory = (category) => {
    setCurrentItem(category);
    setDeleteType('category');
    setDeleteModalOpen(true);
  };

  const handleDeleteSubcategory = (subcategory) => {
    setCurrentItem(subcategory);
    setDeleteType('subcategory');
    setDeleteModalOpen(true);
  };

  const showNotification = (message, type = 'success') => {
    const notification = document.createElement('div');
    notification.className = `alert alert-${type === 'success' ? 'success' : 'error'} fixed top-4 right-4 w-auto z-50`;
    notification.innerHTML = `<span>${message}</span>`;
    document.body.appendChild(notification);
    setTimeout(() => document.body.removeChild(notification), 3000);
  };

  const handleSaveCategory = async (formData) => {
    try {
      let response;
      if (currentItem) {
        response = await axios.put(
          `${API_URL}/categories/${currentItem.id}/`,
          formData,
          {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
          }
        );
        setCategories(categories.map(cat => cat.id === currentItem.id ? response.data : cat));
        showNotification('Catégorie mise à jour avec succès');
      } else {
        response = await axios.post(`${API_URL}/categories/`, formData, {
          headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        setCategories([...categories, response.data]);
        showNotification('Catégorie créée avec succès');
      }
      setCategoryModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde de la catégorie', err);
      showNotification('Impossible de sauvegarder la catégorie', 'error');
    }
  };

  const handleSaveSubcategory = async (formData) => {
    try {
      let response;
      if (currentItem) {
        response = await axios.put(
          `${API_URL}/subcategories/${currentItem.id}/`,
          formData,
          {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
          }
        );
        setSubcategories(subcategories.map(sub => sub.id === currentItem.id ? response.data : sub));
        showNotification('Sous-catégorie mise à jour avec succès');
      } else {
        response = await axios.post(`${API_URL}/subcategories/`, formData, {
          headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        setSubcategories([...subcategories, response.data]);
        showNotification('Sous-catégorie créée avec succès');
      }
      setSubcategoryModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde de la sous-catégorie', err);
      showNotification('Impossible de sauvegarder la sous-catégorie', 'error');
    }
  };

  const handleConfirmDelete = async (item) => {
    try {
      if (deleteType === 'category') {
        await axios.delete(`${API_URL}/categories/${item.id}/`, {
          headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        setCategories(categories.filter(cat => cat.id !== item.id));
        setSubcategories(subcategories.filter(sub => sub.category !== item.id));
        showNotification('Catégorie supprimée avec succès');
      } else {
        await axios.delete(`${API_URL}/subcategories/${item.id}/`, {
          headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        setSubcategories(subcategories.filter(sub => sub.id !== item.id));
        showNotification('Sous-catégorie supprimée avec succès');
      }
      setDeleteModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la suppression', err);
      showNotification('Impossible de supprimer l\'élément', 'error');
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="flex h-96 items-center justify-center">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent motion-reduce:animate-[spin_1.5s_linear_infinite]"></div>
              <p className="mt-4 text-sm text-gray-500">Chargement des catégories...</p>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="p-6">
        {/* En-tête */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Gestion des catégories</h1>
            <p className="mt-2 text-sm text-gray-700">
              Gérez les catégories et sous-catégories de services
            </p>
          </div>
          <div className="flex space-x-3">
            <button
              className="bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 px-4 py-2 rounded-md text-sm font-medium shadow-sm"
              onClick={handleAddSubcategory}
            >
              ➕ Ajouter sous-catégorie
            </button>
            <button
              className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium shadow-sm"
              onClick={handleAddCategory}
            >
              ➕ Ajouter catégorie
            </button>
          </div>
        </div>

        {/* Messages d'erreur */}
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Liste des catégories */}
        {categories.length === 0 ? (
          <div className="bg-white shadow-sm rounded-lg">
            <div className="px-4 py-12 text-center">
              <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
              </svg>
              <h3 className="mt-4 text-sm font-medium text-gray-900">Aucune catégorie</h3>
              <p className="mt-2 text-sm text-gray-500">
                Commencez par ajouter votre première catégorie de services.
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            {categories.map((category) => {
              const categorySubcategories = subcategories.filter(sub => sub.category === category.id);
              const isExpanded = expandedCategory === category.id;
              
              return (
                <div key={category.id} className="bg-white shadow-sm rounded-lg overflow-hidden">
                  {/* En-tête de catégorie */}
                  <div
                    className={`px-6 py-4 cursor-pointer hover:bg-gray-50 ${
                      isExpanded ? 'border-b border-gray-200' : ''
                    }`}
                    onClick={() => toggleCategory(category.id)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                          <span className="text-indigo-600 font-medium">📂</span>
                        </div>
                        <div>
                          <h3 className="text-sm font-medium text-gray-900">{category.name}</h3>
                          <p className="text-sm text-gray-500">
                            {categorySubcategories.length} sous-catégorie{categorySubcategories.length !== 1 ? 's' : ''}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          className="text-gray-400 hover:text-indigo-600 p-1"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleEditCategory(category);
                          }}
                        >
                          ✏️
                        </button>
                        <button
                          className="text-gray-400 hover:text-red-600 p-1"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeleteCategory(category);
                          }}
                        >
                          🗑️
                        </button>
                        <svg
                          className={`h-5 w-5 text-gray-400 transform transition-transform ${
                            isExpanded ? 'rotate-180' : ''
                          }`}
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                      </div>
                    </div>
                  </div>

                  {/* Contenu étendu */}
                  {isExpanded && (
                    <div className="px-6 py-4 bg-gray-50">
                      {category.description && (
                        <p className="text-sm text-gray-600 mb-4">{category.description}</p>
                      )}
                      
                      {category.image_url && (
                        <div className="mb-4 flex items-center text-sm text-gray-600">
                          <span className="mr-2">🖼️</span>
                          <a
                            href={category.image_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-indigo-600 hover:text-indigo-800 underline"
                          >
                            Voir l'image
                          </a>
                        </div>
                      )}

                      <div>
                        <h4 className="text-sm font-medium text-gray-900 mb-3">Sous-catégories</h4>
                        {categorySubcategories.length === 0 ? (
                          <p className="text-sm text-gray-500 italic">
                            Aucune sous-catégorie pour cette catégorie.
                          </p>
                        ) : (
                          <div className="space-y-2">
                            {categorySubcategories.map((subcategory) => (
                              <div
                                key={subcategory.id}
                                className="flex items-center justify-between bg-white rounded-lg p-3 border border-gray-200"
                              >
                                <div className="flex items-center space-x-3">
                                  <span className="text-gray-400">↳</span>
                                  <div>
                                    <h5 className="text-sm font-medium text-gray-900">
                                      {subcategory.name}
                                    </h5>
                                    {subcategory.description && (
                                      <p className="text-sm text-gray-500 mt-1">
                                        {subcategory.description.length > 100
                                          ? `${subcategory.description.substring(0, 100)}...`
                                          : subcategory.description}
                                      </p>
                                    )}
                                  </div>
                                </div>
                                <div className="flex space-x-1">
                                  <button
                                    className="text-gray-400 hover:text-indigo-600 p-1"
                                    onClick={() => handleEditSubcategory(subcategory)}
                                  >
                                    ✏️
                                  </button>
                                  <button
                                    className="text-gray-400 hover:text-red-600 p-1"
                                    onClick={() => handleDeleteSubcategory(subcategory)}
                                  >
                                    🗑️
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* Modales */}
        {categoryModalOpen && (
          <CategoryModal
            category={currentItem}
            onSave={handleSaveCategory}
            onCancel={() => setCategoryModalOpen(false)}
          />
        )}

        {subcategoryModalOpen && (
          <SubcategoryModal
            subcategory={currentItem}
            categories={categories}
            onSave={handleSaveSubcategory}
            onCancel={() => setSubcategoryModalOpen(false)}
          />
        )}

        {deleteModalOpen && currentItem && (
          <DeleteConfirmationModal
            item={currentItem}
            itemType={deleteType}
            onConfirm={handleConfirmDelete}
            onCancel={() => setDeleteModalOpen(false)}
          />
        )}
      </div>
    </DashboardLayout>
  );
};

export default withAuth(Categories);