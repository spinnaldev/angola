from modeltranslation.translator import translator, TranslationOptions
from .models import Category, SubCategory, ProviderService

# class CategoryTranslationOptions(TranslationOptions):
#     fields = ('name', 'description')

# class SubCategoryTranslationOptions(TranslationOptions):
#     fields = ('name', 'description')

class ProviderServiceTranslationOptions(TranslationOptions):
    fields = ('title', 'description')

# Enregistrement
# translator.register(Category, CategoryTranslationOptions)
# translator.register(SubCategory, SubCategoryTranslationOptions)
translator.register(ProviderService, ProviderServiceTranslationOptions)