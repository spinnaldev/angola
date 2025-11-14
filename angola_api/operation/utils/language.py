from django.utils.translation import get_language

def get_translated_field(obj, field_name):
    """
    Récupère la valeur traduite d'un champ selon la langue active
    """
    current_language = get_language()
    
    # Essayer d'abord avec la langue courante
    translated_field = f"{field_name}_{current_language}"
    if hasattr(obj, translated_field):
        value = getattr(obj, translated_field, None)
        if value:
            return value
    
    # Fallback sur le champ par défaut
    return getattr(obj, field_name, '')