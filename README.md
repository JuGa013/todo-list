# Todo list API
Une simple API Todo List faite avec Symfony.

### Démarrer le projet
```
git clone https://github.com/JuGa013/todo-list.git todo-list
cd todo-list
make init
```

Par défaut accessible sur localhost:8012

## Axes de travail
### Structure générale
* créer une List
  * nom (string)
  * description (string)
  * date de création (datetime_immutable)
  * date d'update (datetime)
  * état done (boolean)
  * archivé  (boolean)
* créer des ListItem (choses à faire dans une liste)
  * liste (FK_List)
  * label (string)
  * état done (boolean)
  * date de création (datetime_immutable)
  * date d'update (datetime)

### Actions
* CRUD d'une liste
  * PATCH done
  * PATCH archive
  * DELETE doit delete tous les items liés
* CRUD d'un item
  * PATCH done

## Axes d'amélioration
* lier à un user
  * authentification (lexik/jwk-token + gesdinet/refresh-token)
* donner une couleur à une liste
* partager une liste
  * soit via lien (public ouvert)
  * soit partage ciblé avec droits (lecture, écriture)
* lier une liste à une catégorie 
  * auto création de la catégorie (style tag)
  * filtre des listes par catégorie
  * ajout massif de listes à une catégorie 
* ajouter une date butoire sur une liste et/ou sur un item

