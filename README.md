# KickOff ⚽️🏀🎾

**KickOff** est une app iOS sociale permettant aux fans de sport de suivre, noter et débattre des performances de leurs équipes favorites. 

Développée en **SwiftUI**, l'app propose une interface fluide et interactive pour logger les matchs visionnés, attribuer des notes de type Letterboxd et suivre son évolution via un système de gamification.

##  Aperçu des Fonctionnalités

### 1. Fil d'actualité 
* **Feed dynamique** : Affichage des matchs en direct ("Live") et des tendances des dernières 72h.
* **Filtrage par sport** : Navigation dédiée pour le football, le basketball et le tennis.
* **Recherche avancée** : Moteur de recherche pour trouver des compétitions, équipes ou joueurs spécifiques.

### 2. Système de Notation & Logs
* **Jauge de Score Interactive** : Une jauge de précision (0 à 10) avec retour visuel colorimétrique (dégradé rouge vers vert) pour noter la qualité du match.
* **Reviews** : Possibilité d'ajouter une critique et des hashtags pour chaque match loggé.
* **Historique** : Sauvegarde locale des logs utilisateurs.

### 3. Gamification & Profil
* **Badges** : Système de récompenses automatiques (ex: "Rookie", "Analyste", "Hall of Fame") calculé selon le nombre de logs et de reviews.
* **Stats Utilisateur** : Suivi du nombre de matchs vus, sports favoris et progression.
* **Personnalisation** : Gestion de profil, avatar et favoris.

##  Architecture & Stack Technique

Le projet est conçu avec une architecture robuste pour garantir maintenabilité et évolutivité :

* **Langage** : Swift 5
* **Interface** : SwiftUI (Utilisation extensive de `Grid`, `NavigationStack`, `Animations`).
* **Architecture** : MVVM (Model-View-ViewModel).
* **Data & Networking** : 
    * `APIClient` conçu pour basculer entre un environnement **Mock** (données simulées pour le dev) et **Live** (API réelle).
    * Gestion de la concurrence avec Swift **Async/Await**.
* **Persistance** : `UserDefaults` pour le stockage local des préférences, de l'authentification simulée et des logs (MVP).
* **Tests** : Unit Tests et UI Tests intégrés via XCTest.

##  Installation et Lancement

1.  Cloner le projet :
    ```bash
    git clone [https://github.com/ton-username/KickOff-App.git](https://github.com/ton-username/KickOff-App.git)
    ```
2.  Ouvrir le fichier `Kickoff.xcodeproj` dans **Xcode 16+**.
3.  Sélectionner un simulateur (ex: iPhone 15 Pro) ou un appareil réel.
4.  Lancer le build avec `Cmd + R`.

> **Note :** L'application est configurée par défaut en mode `.mock` dans `KickoffApp.swift`. Aucune connexion serveur n'est requise pour tester les fonctionnalités principales.

##  État Actuel & Roadmap Technique

Le projet est actuellement en phase de **MVP**. Certaines fonctionnalités sont simulées (Mock) pour valider l'UX/UI avant l'intégration back-end complexe.

### Ce qui est implémenté 
* Architecture MVVM et Navigation complète.
* Système de logs manuels et persistance locale (UserDefaults).
* Calcul dynamique des badges (Gamification).
* Interface "Feed" et "Détail Match" avec données simulées.

### Ce qu'il reste à faire:

#### 1. Intégration API & Automatisation (Prio 1)
L'objectif est de supprimer la saisie manuelle des résultats pour passer à un flux automatique.
* **Connexion API Sportive** : Remplacement des `MockData` par une API réelle (ex: *API-Football* ou *TheSportsDB*) pour récupérer les scores, compositions et calendriers en temps réel.
* **Auto-Logging** : Log automatique des matchs visionnés via validation géolocalisée ou check-in, au lieu de la sélection manuelle.

#### 2. Data Science & IA (Objectif Master I2D) 🧠
Exploitation des données générées par les utilisateurs :
* **Moteur de Recommandation** : Algorithme (Collaborative Filtering) pour suggérer des matchs à voir en fonction de l'historique des notes de l'utilisateur.
* **Analyse Prédictive** : Affichage de stats avancées dans la vue détail (ex: probabilité de victoire) basées sur des modèles historiques.

#### 3. Fonctionnalités Sociales & Backend
* **Onglet "Direct" (Chat)** : Implémentation pour permettre les débats en direct pendant les matchs (actuellement placeholder).
* **Authentification & Cloud** : Migration du stockage local (`UserDefaults`) vers une base de données distante pour gérer les comptes utilisateurs sur plusieurs appareils .
