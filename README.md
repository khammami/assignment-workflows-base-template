# Travail à faire (Compte Rendu) - template

> [!WARNING]  
> Instructions to complete and submit this assignment.

## Créer et exécuter une application

* App description here. What to do here.

## Répondre à ces questions

### **Question 1**

**Q1.** Question here

📋 **A1.** Choisissez-en un:

* [ ] **(a)** `answer1`
* [ ] **(b)** `answer2`
* [ ] **(c)** `answer3`
* [ ] **(d)** `answer4`

### **Question 2**

**Q2.** Question here

📋 **A2.** Choisissez-en un:

* [ ] **(a)** `answer1`
* [ ] **(b)** `answer2`
* [ ] **(c)** `answer3`
* [ ] **(d)** `answer4`

### **Question 3**

**Q3.** Question here

📋 **A3.** Choisissez-en un:

* [ ] **(a)** answer1
* [ ] **(b)** answer2
* [ ] **(c)** answer3
* [ ] **(d)** answer4

### **Question 4**

**Q4.** Question here

```java
HelloWorld{
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```

More description here.

📋 **A4.** Choisissez-en un:

* [ ] **(a)** answer1
* [ ] **(b)** answer2
* [ ] **(c)** answer3
* [ ] **(d)** answer4
* [ ] **(e)** answer5
* [ ] **(f)** answer6

## Notes

> [!NOTE]  
>
> Note here

## Dépannage du workflow (CI)

Si le workflow GitHub Actions échoue, suivez ces étapes localement avant de re-pousser:

1) Vérifiez la structure du projet

   * Placez votre application dans le dossier `application/` comme demandé.
   * Vérifiez que le fichier `README.md` est à la racine du projet.

2) Formatage du code (Spotless)

   * Vérifiez le formatage localement (utilisez le fichier init-script présent dans `.github`):

    ```bash
    ./gradlew --init-script .github/spotless.init.gradle spotlessCheck
    ```

   * Corrigez automatiquement le formatage:

    ```bash
    ./gradlew --init-script .github/spotless.init.gradle spotlessApply
    ```

   * Validez vos changements:

    ```bash
    # * branche `dev`
    git add -A
    git commit -m "style: apply Spotless formatting"
    ```

3) Relancez le `workflow`

   * Poussez vos corrections sur la branche `dev` ou relancez manuellement le `workflow` dans l’onglet “Actions”.

    ```bash
    # * branche `dev`
    git push
    ```

> [!IMPORTANT]
> Si vous rencontrez des problèmes, n'hésitez pas à demander de l'aide en ouvrant une `issue` sur le dépôt GitHub.
