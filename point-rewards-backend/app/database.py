# -*- coding: utf-8 -*-
"""
Database setup and initialization.
- Creates the SQLAlchemy database instance.
- Defines a CLI command to create database tables.
"""
import click
from flask.cli import with_appcontext
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy.ext.declarative import declarative_base

# SQLAlchemy instance
# This object provides access to all SQLAlchemy functions and helpers.
# It's initialized here but configured in the application factory.
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


@click.command('init-db')
@with_appcontext
def init_db_command():
    """CLI command to clear existing data and create new tables."""
    db.drop_all() # In a real production environment, you might want to use migrations (e.g., with Alembic) instead of drop_all.
    db.create_all()
    click.echo('Initialized the database.')
