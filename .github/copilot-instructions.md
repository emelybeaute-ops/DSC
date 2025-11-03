## Objectif

Fournir des modifications de code petites et précises pour le dépôt DSC (Desired State Configuration v3). Ce fichier contient des instructions pratiques et spécifiques au projet pour qu'un agent IA soit immédiatement productif.

## Vue d'ensemble (à connaître en premier)
- Il s'agit d'un workspace Rust (consulter le `Cargo.toml` à la racine). Le binaire principal est le crate `dsc/` (génère `dsc`/`dsc.exe`). Les bibliothèques partagées sont dans `lib/`, les ressources dans `resources/`, les adaptateurs dans `adapters/` et les outils d'aide dans `tools/`.
- Flux typique : la CLI `dsc` appelle des crates ressources (binaires) et utilise des schémas JSON (`*.dsc.resource.json`). Exemples : `resources/osinfo`, `resources/registry` (exécutable + manifeste `.dsc.resource.json`).
- Les grammaires tree-sitter sont dans `grammars/` et sont transformées en bindings à la compilation. `y2j` est un utilitaire YAML→JSON utilisé par certains pipelines.

## Compilation & tests (commandes et attentes)
- Point d'entrée préféré : les scripts PowerShell à la racine. Utilisez `build.new.ps1` (workflow moderne). Il configure rustup, installe Node/tree-sitter si nécessaire, génère les bindings, construit les crates dans l'ordre attendu et copie les artefacts dans `bin/`.
  - Exemples (PowerShell / pwsh) :
```powershell
./build.new.ps1
./build.new.ps1 -Release -Architecture x86_64-unknown-linux-gnu
./build.new.ps1 -Test
./build.new.ps1 -PackageType tgz -Architecture x86_64-unknown-linux-gnu
```
- Le script legacy `build.ps1` existe encore et sert pour des comparaisons (voir `build.comparison.ps1`). Privilégiez `build.new.ps1` pour les nouvelles contributions.
- Des tâches VS Code existent (`DSC: Build`, `DSC: Test (All)`, `DSC: Test Rust`) ; elles invoquent les mêmes scripts — utilisez-les pour la cohérence locale.

## Conventions spécifiques
- `default-members` dans le workspace est utilisé pour accélérer les builds locaux ; les mainteneurs emploient `Set-DefaultWorkspaceMember`. N'engagez pas de modifications non motivées dans `Cargo.toml`.
- `copy_files.txt` doit utiliser '/' (slash) comme séparateur. Les scripts échouent ou se comportent mal si des backslashes sont utilisés.
- Une ressource typique : un binaire + `<name>.dsc.resource.json`. Les scripts de packaging s'attendent à des noms précis (voir `filesForWindowsPackage`/`filesForLinuxPackage` dans `build.ps1`).
- Clippy : le build peut exécuter Clippy avec des niveaux pedantic pour certains crates. Quelques projets sont exclus (cf. `clippy_unclean_projects` dans `build.ps1`). Respectez ces exceptions si vous modifiez la configuration Clippy.

## Points d'intégration externes
- Pester / PowerShell : les adaptateurs PowerShell et les tests Pester sont gérés par le processus de test (`build.new.ps1 -Test`). Sur Windows, certains modules (ex. `PSDesiredStateConfiguration`) sont installés automatiquement si nécessaire.
- tree-sitter : si absent, le script peut installer `tree-sitter-cli` via Cargo.
- Packaging MSIX (Windows) : nécessite `makeappx`/`makepri` (Windows SDK). Le packaging suit la logique définie dans `build.new.ps1` / `build.ps1` — ne réinventez pas le processus manuellement.
- Index privé (CFS) : les scripts supportent un index Cargo privé et l'authentification via `az` (`-UseCFSAuth`). Évitez de modifier la résolution des sources Cargo sans coordination.

## Actions courantes et où modifier
- Modifier la CLI : éditez `dsc/src` et `dsc/Cargo.toml`. `dsc` est le point d'entrée — mettez à jour les textes d'aide dans le crate.
- Ajouter une ressource : créer un crate exécutable sous `resources/`, ajouter `<name>.dsc.resource.json` et, si besoin, un `copy_files.txt` pour inclure d'autres fichiers.
- Changer un comportement global : favorisez un changement local et validez via `./build.new.ps1 -Test` sur la plateforme cible.

## Exemples concrets du dépôt
- L'ordre de compilation et les listes de projets par OS sont codés dans `build.ps1` et repris par `build.new.ps1` — utile pour investiguer des erreurs de build en CI.
- Les fichiers inclus dans les packages sont explicitement listés dans `build.ps1` (`filesForWindowsPackage`, etc.). Si vous ajoutez un binaire, mettez à jour ces listes.
- Les schémas JSON utilisent `serde`, `schemars` et `jsonschema` (voir les dépendances du workspace). Maintenez l'ordre stable pour `serde_json` si le code en dépend.

## Sécurité / bonnes pratiques avant PR
- Lancez `./build.new.ps1 -Test` localement avant d'ouvrir une PR. Si vous modifiez le manifeste du workspace ou `default-members`, documentez la raison et exécutez l'ensemble des tests.
- Ne modifiez pas les variables d'environnement globales en CI sans coordination (les scripts ajustent rustup/cargo et peuvent configurer des index privés).

## Tâches VS Code (raccourci)
Les tâches VS Code définies dans le workspace pointent sur les mêmes scripts PowerShell. Elles sont pratiques pour exécuter les workflows depuis l'IDE :
- `DSC: Build` — construit les crates et copie les artefacts vers `bin/` (utilise `./build.new.ps1`).
- `DSC: Test (All)` — exécute les tests Rust et Pester, optionnellement en sautant la compilation (utilise `./build.new.ps1 -Test`).
- `DSC: Test Rust` — exécute uniquement les tests Rust en appelant `./build.new.ps1 -Test -ExcludePesterTests`.

Utilisez ces tâches pour lancer les builds/tests depuis VS Code (Palette de commandes → Tasks), elles transmettent les mêmes paramètres que les exemples en ligne de commande.

## Prérequis système et permissions
Quelques opérations du script `./build.new.ps1 -Test` peuvent installer ou configurer des outils système (rustup, Node.js, tree-sitter, Visual Studio Build Tools, makeappx/makepri). Attention :
- Sur Windows, l'installation des Visual Studio Build Tools ou de `makeappx`/`makepri` peut nécessiter des privilèges administrateurs.
- Le script peut installer des modules PowerShell (Pester, PSDesiredStateConfiguration) et peut écrire dans des emplacements système ou utilisateur selon l'installation — prévoyez suffisamment d'espace disque et d'autorisations.
- Si vous utilisez un index Cargo privé (`-UseCFS` / `-UseCFSAuth`), le script peut appeler `az` pour obtenir un jeton ; assurez-vous que l'Azure CLI est installée et que vous êtes connecté si nécessaire.

Conseil : pour des validations rapides, exécutez d'abord `./build.new.ps1 -SkipBuild -Test` (si vous avez déjà des artefacts dans `bin/`) ou exécutez une seule tâche (`DSC: Test Rust`) pour limiter les installations automatiques.

Si vous souhaitez que j'ajoute des exemples par crate, des commandes MSIX détaillées pour Windows, ou la liste des tâches VS Code, dites-moi quelles sections développer et j'itérerai.
