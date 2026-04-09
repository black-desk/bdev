---
name: create-from-template
description: Create a new project from a template repository by replacing placeholder strings
---

1. Use git commands to
   determine the actual project name and repository location:
   ```bash
   git remote -v
   ```

2. Read all files in the project. Understand project struct.
   Use available scripts in project or any other command line tools looking for:

   1. TODOs
   2. Strings that need to be replaced, such as
      "template", "YOUR NAME", and other obvious placeholder text.

3. You should replace those strings with the actual project name.

4. Recheck TODOs in the project to
   ensure you have completed all TODOs related to the project name.
