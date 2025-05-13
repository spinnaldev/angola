import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { withAuth } from '../context/AuthContext';
import axios from 'axios';

// Icônes
import CategoryIcon from '@mui/icons-material/Category';
import SubdirectoryArrowRightIcon from '@mui/icons-material/SubdirectoryArrowRight';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import ImageIcon from '@mui/icons-material/Image';

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
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-text-primary">
              {category ? 'Modifier la catégorie' : 'Ajouter une catégorie'}
            </h3>
            <button
              className="absolute top-4 right-4 text-text-disabled hover:text-text-secondary"
              onClick={onCancel}
            >
              &times;
            </button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="p-6">
              <div className="mb-4">
                <label className="label" htmlFor="name">
                  Nom
                </label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  className="input w-full"
                  value={formData.name}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="description">
                  Description
                </label>
                <textarea
                  id="description"
                  name="description"
                  className="input w-full"
                  rows="3"
                  value={formData.description}
                  onChange={handleChange}
                ></textarea>
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="icon">
                  Icône (classe CSS)
                </label>
                <input
                  type="text"
                  id="icon"
                  name="icon"
                  className="input w-full"
                  value={formData.icon}
                  onChange={handleChange}
                  placeholder="Ex: home, person, etc."
                />
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="image_url">
                  URL de l'image
                </label>
                <input
                  type="url"
                  id="image_url"
                  name="image_url"
                  className="input w-full"
                  value={formData.image_url}
                  onChange={handleChange}
                  placeholder="https://example.com/image.jpg"
                />
              </div>
            </div>

            <div className="border-t bg-gray-50 px-6 py-4">
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                  onClick={onCancel}
                >
                  Annuler
                </button>
                <button type="submit" className="btn btn-primary">
                  Enregistrer
                </button>
              </div>
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
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-text-primary">
              {subcategory ? 'Modifier la sous-catégorie' : 'Ajouter une sous-catégorie'}
            </h3>
            <button
              className="absolute top-4 right-4 text-text-disabled hover:text-text-secondary"
              onClick={onCancel}
            >
              &times;
            </button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="p-6">
              <div className="mb-4">
                <label className="label" htmlFor="category">
                  Catégorie parente
                </label>
                <select
                  id="category"
                  name="category"
                  className="input w-full"
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

              <div className="mb-4">
                <label className="label" htmlFor="name">
                  Nom
                </label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  className="input w-full"
                  value={formData.name}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="description">
                  Description
                </label>
                <textarea
                  id="description"
                  name="description"
                  className="input w-full"
                  rows="3"
                  value={formData.description}
                  onChange={handleChange}
                ></textarea>
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="icon">
                  Icône (classe CSS)
                </label>
                <input
                  type="text"
                  id="icon"
                  name="icon"
                  className="input w-full"
                  value={formData.icon}
                  onChange={handleChange}
                  placeholder="Ex: home, person, etc."
                />
              </div>
            </div>

            <div className="border-t bg-gray-50 px-6 py-4">
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                  onClick={onCancel}
                >
                  Annuler
                </button>
                <button type="submit" className="btn btn-primary">
                  Enregistrer
                </button>
              </div>
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
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-text-primary">
              Confirmer la suppression
            </h3>
          </div>
          <div className="p-6">
            <p className="text-text-secondary">
              Êtes-vous sûr de vouloir supprimer {itemType === 'category' ? 'la catégorie' : 'la sous-catégorie'}{' '}
              <span className="font-medium text-text-primary">"{item.name}"</span>?
              {itemType === 'category' && (
                <span className="mt-2 block font-medium text-error">
                  Attention: Toutes les sous-catégories associées seront également supprimées.
                </span>
              )}
            </p>
          </div>
          <div className="border-t bg-gray-50 px-6 py-4">
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                onClick={onCancel}
              >
                Annuler
              </button>
              <button
                type="button"
                className="btn bg-error text-white hover:bg-red-700"
                onClick={() => onConfirm(item)}
              >
                Supprimer
              </button>
            </div>
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
    const category = categories.find(
      (cat) => cat.id === subcategory.category
    );
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

  const handleSaveCategory = async (formData) => {
    try {
      let response;
      if (currentItem) {
        // Mise à jour
        response = await axios.put(
          `${API_URL}/categories/${currentItem.id}/`,
          formData,
          {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
          }
        );
        setCategories(
          categories.map((cat) =>
            cat.id === currentItem.id ? response.data : cat
          )
        );
        setSuccess('Catégorie mise à jour avec succès');
      } else {
        // Création
        response = await axios.post(`${API_URL}/categories/`, formData, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        setCategories([...categories, response.data]);
        setSuccess('Catégorie créée avec succès');
      }
      setCategoryModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde de la catégorie', err);
      setError('Impossible de sauvegarder la catégorie. Veuillez réessayer.');
    }
  };

  const handleSaveSubcategory = async (formData) => {
    try {
      let response;
      if (currentItem) {
        // Mise à jour
        response = await axios.put(
          `${API_URL}/subcategories/${currentItem.id}/`,
          formData,
          {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
          }
        );
        setSubcategories(
          subcategories.map((sub) =>
            sub.id === currentItem.id ? response.data : sub
          )
        );
        setSuccess('Sous-catégorie mise à jour avec succès');
      } else {
        // Création
        response = await axios.post(`${API_URL}/subcategories/`, formData, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        setSubcategories([...subcategories, response.data]);
        setSuccess('Sous-catégorie créée avec succès');
      }
      setSubcategoryModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde de la sous-catégorie', err);
      setError('Impossible de sauvegarder la sous-catégorie. Veuillez réessayer.');
    }
  };

  const handleConfirmDelete = async (item) => {
    try {
      if (deleteType === 'category') {
        await axios.delete(`${API_URL}/categories/${item.id}/`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        setCategories(categories.filter((cat) => cat.id !== item.id));
        setSubcategories(subcategories.filter((sub) => sub.category !== item.id));
        setSuccess('Catégorie supprimée avec succès');
      } else {
        await axios.delete(`${API_URL}/subcategories/${item.id}/`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        setSubcategories(subcategories.filter((sub) => sub.id !== item.id));
        setSuccess('Sous-catégorie supprimée avec succès');
      }
      setDeleteModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la suppression', err);
      setError('Impossible de supprimer l\'élément. Veuillez réessayer.');
    }
  };

  // Effacer les messages après 5 secondes
  useEffect(() => {
    if (success) {
      const timer = setTimeout(() => setSuccess(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [success]);

  useEffect(() => {
    if (error) {
      const timer = setTimeout(() => setError(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [error]);

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-text-primary">
            Gestion des catégories
          </h1>
          <div className="mt-4 flex space-x-4 md:mt-0">
            <button
              className="btn btn-outline"
              onClick={handleAddSubcategory}
            >
              <AddIcon className="mr-1 h-5 w-5" />
              Ajouter une sous-catégorie
            </button>
            <button
              className="btn btn-primary"
              onClick={handleAddCategory}
            >
              <AddIcon className="mr-1 h-5 w-5" />
              Ajouter une catégorie
            </button>
          </div>
        </div>

        {/* Messages de succès et d'erreur */}
        {success && (
          <div className="rounded-md bg-success/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <p className="text-sm font-medium text-success">{success}</p>
              </div>
            </div>
          </div>
        )}

        {error && (
          <div className="rounded-md bg-error/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-error">Erreur</h3>
                <div className="mt-2 text-sm text-error">{error}</div>
              </div>
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="text-center">
              <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
              <p className="mt-2 text-text-secondary">
                Chargement des catégories...
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-6">
            {categories.length === 0 ? (
              <div className="card flex h-32 items-center justify-center">
                <p className="text-text-secondary">
                  Aucune catégorie trouvée. Commencez par en ajouter une.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {categories.map((category) => {
                  const categorySubcategories = subcategories.filter(
                    (sub) => sub.category === category.id
                  );
                  return (
                    <div
                      key={category.id}
                      className="card overflow-hidden p-0"
                    >
                      <div
                        className={`flex cursor-pointer items-center justify-between p-4 ${
                          expandedCategory === category.id
                            ? 'border-b'
                            : ''
                        }`}
                        onClick={() => toggleCategory(category.id)}
                      >
                        <div className="flex items-center">
                          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                            <CategoryIcon className="text-primary" />
                          </div>
                          <div className="ml-4">
                            <h3 className="font-medium text-text-primary">
                              {category.name}
                            </h3>
                            <p className="text-sm text-text-secondary">
                              {categorySubcategories.length} sous-catégories
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center">
                          <button
                            className="ml-2 text-text-secondary hover:text-primary"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleEditCategory(category);
                            }}
                          >
                            <EditIcon fontSize="small" />
                          </button>
                          <button
                            className="ml-2 text-text-secondary hover:text-error"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteCategory(category);
                            }}
                          >
                            <DeleteIcon fontSize="small" />
                          </button>
                        </div>
                      </div>
                      {expandedCategory === category.id && (
                        <div className="bg-gray-50 p-4">
                          {category.description && (
                            <p className="mb-4 text-text-secondary">
                              {category.description}
                            </p>
                          )}
                          {category.image_url && (
                            <div className="mb-4 flex items-center">
                              <ImageIcon className="mr-2 text-text-secondary" />
                              <a
                                href={category.image_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-sm text-primary hover:text-primary-dark"
                              >
                                Voir l'image
                              </a>
                            </div>
                          )}
                          <h4 className="mb-2 font-medium text-text-primary">
                            Sous-catégories
                          </h4>
                          {categorySubcategories.length === 0 ? (
                            <p className="text-sm text-text-secondary">
                              Aucune sous-catégorie pour cette catégorie.
                            </p>
                          ) : (
                            <div className="space-y-2">
                              {categorySubcategories.map((subcategory) => (
                                <div
                                  key={subcategory.id}
                                  className="flex items-center justify-between rounded-lg border bg-white p-3"
                                >
                                  <div className="flex items-center">
                                    <SubdirectoryArrowRightIcon className="mr-2 text-text-disabled" />
                                    <div>
                                      <h5 className="font-medium text-text-primary">
                                        {subcategory.name}
                                      </h5>
                                      {subcategory.description && (
                                        <p className="text-sm text-text-secondary">
                                          {subcategory.description.length > 100
                                            ? `${subcategory.description.substring(0, 100)}...`
                                            : subcategory.description}
                                        </p>
                                      )}
                                    </div>
                                  </div>
                                  <div className="flex">
                                    <button
                                      className="ml-2 text-text-secondary hover:text-primary"
                                      onClick={() => handleEditSubcategory(subcategory)}
                                    >
                                      <EditIcon fontSize="small" />
                                    </button>
                                    <button
                                      className="ml-2 text-text-secondary hover:text-error"
                                      onClick={() => handleDeleteSubcategory(subcategory)}
                                    >
                                      <DeleteIcon fontSize="small" />
                                    </button>
                                  </div>
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
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