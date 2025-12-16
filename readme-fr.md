<h1>
    <a href="readme-fr.md"><img src="https://img.icons8.com/color/48/000000/france-circular.png" width="30" alt="Français"/></a>
    <a href="readme.md"><img src="https://img.icons8.com/color/48/000000/great-britain-circular.png" width="30" alt="English"/></a> 
    NexaCore
</h1>

## ℹ️ Introduction

## 🛠️ Installation
### Télécharger le dépôt

### Installer les package :

```cmd
  # Swagger
  dotnet add package Swashbuckle.AspNetCore --version 6.6.2
```

Base de données:
```cmd
  # Dans Ticketing.Api
  dotnet add package Microsoft.EntityFrameworkCore --version 8.0.8
  dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 8.0.8
  dotnet add package Microsoft.EntityFrameworkCore.Tools --version 8.0.8

  # Migration + DB
  dotnet ef migrations add InitDb
  dotnet ef database update
```


## 📚 Documentation
- **Cahier des charges**
  - [Cahier des Charges Fonctionnel](Documents/fonctional-specification-fr.md)
  - [Cahier des Charges Technique](Documents/technical-specification-fr.md)

## Utilisation 
Lancement du projet:
```cmd
  dotnet run
```
Acceder a l'application en local (http://localhost:5192)[http://localhost:5192]

Verrification de l'etat de l'application (http://localhost:5192/swagger)[http://localhost:5192/swagger]

## 👤 Auteurs et collaborateurs
<table style="border-collapse: collapse; border: none; width: 100%">
  <!-- Column 1 - Max 3 profils -->
  <tr style="border: none">
    <!-- Contributeur 1 -->
    <td
      style="
        border: none;
        padding: 10px;
        text-align: center;
        vertical-align: top;
        width: 33%;
      "
    >
      <table
        style="border-collapse: collapse; border: none; display: inline-block"
      >
        <tr style="border: none">
          <td style="border: none; padding: 5px; text-align: center">
            <a href="https://github.com/lchouville">
              <img
                src="https://avatars.githubusercontent.com/u/51326118?v=4"
                width="100px;"
                alt="Luka Chouville"
              />
            </a>
          </td>
          <td style="border: none; padding: 5px; text-align: left">
            <p style="text-align: center;"><strong>Luka Chouville</strong></p>
            <p style="text-align: center;font-size:17px">Project Leader</p>
            <a
              href="https://www.linkedin.com/in/luka-chouville-6abb3717a"
              style="text-decoration: none"
            >
              <img
                src="https://img.icons8.com/color/20/000000/linkedin.png"
                style="vertical-align: middle"
              />
              LinkedIn </a
            ><br />
            <a
              href="https://github.com/lchouville"
              style="text-decoration: none"
            >
              <img
                src="https://img.icons8.com/ios-filled/20/000000/github.png"
                style="vertical-align: middle"
              />
              GitHub </a
            ><br />
            <a
              href="mailto:luka.chouville@laposte.net"
              style="text-decoration: none"
            >
              <img
                src="https://img.icons8.com/color/20/000000/gmail.png"
                style="vertical-align: middle"
              />
              luka.chouville@laposte.net
            </a>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>