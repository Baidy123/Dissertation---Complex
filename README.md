# Project Overview

This folder is divided into two main parts:

1. **Game Project Files**
2. **User Questionnaire Feedback**

---

## 1. Game Project Files

The game project can be opened directly in an IDE. However, this approach will not allow for an intuitive inspection of the game's code structure, node hierarchy, or interface elements.

To explore the project more effectively, we recommend using the **Godot Engine 4.3 (Stable)** version.

Download here: [https://godotengine.org/download/archive/4.3-stable/](https://godotengine.org/download/archive/4.3-stable/)  
After downloading, open the project within the Godot engine to view it more interactively.

---

## 2. User Questionnaire Feedback

The `data` folder contains the processed results of the user questionnaire.

To view the analysis results:

- Run `ANOVA.py` and `Tukey_HSD.py` to see results related to **Playability**.
- Run `MANOVA.py` to see results related to **PENS (Player Experience of Need Satisfaction)**.

---

## Environment Setup

Before running any Python scripts, please ensure the required libraries are installed by entering the following command in your terminal:

```bash
pip install pandas statsmodels numpy scipy openpyxl
```

---

# Final Note
**Thank you for reviewing this project.**

**We hope that one day, building upon this foundation, we can develop a real game.**

**Per aspera ad astra.**
