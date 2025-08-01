# -*- coding: utf-8 -*-
"""
Initializes the 'api' module as a Flask Blueprint.
This file groups all API route modules into a single blueprint for cleaner registration in the main app.
"""
from flask import Blueprint

# Create a Blueprint for the API.
# This acts as a container for all API-related routes.
api_bp = Blueprint('api', __name__)

# Import the route modules to ensure they are registered with the blueprint.
# These imports are placed here to avoid circular dependency issues.
from . import users, prizes, redemptions, history
