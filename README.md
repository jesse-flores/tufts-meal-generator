# 🥗 Tufts Dewick Meal Generator

A Ruby-based command-line tool to generate personalized meal plans from the **Tufts Dewick Dining Hall** menu using live data from the Nutrislice API. The generator helps students meet daily nutrition goals by recommending balanced meals for breakfast, lunch, and dinner.

---

## 🚀 Features
    📅 Date-based meal planning – Choose any date and get meal options for breakfast, lunch, and dinner.

    🧠 Nutrition-aware recommendations – Set custom calorie and protein goals, and receive meals tailored to hit those targets.

    🥦 Balanced food categories – Ensures your meals include protein, veggies, grains, fruits, and dairy.

    🔍 Smart food filtering – Filters out menu items without nutrition data and prioritizes protein-rich items.

    📊 Nutrition breakdown – View total calories, protein, carbs, and fat per meal and for the full day.

    ✅ Food group checklist – Track what categories your meal plan covers

---

## Installation

1. Clone this repo:

```bash
git clone https://github.com/jesse-flores/tufts-meal-generator.git
cd tufts-meal-generator
```

2. Install all dependencies:

```bash
gem install tty-prompt
```

3. Run the program:
```bash
ruby tufts_diet_planner.rb
```

## How it works
### API Fetching
- Connects to Tufts Dewick Dining's API to get the menu for a given date and meal type.

### Item Processing
- Parses and cleans menu items, extracting calorie/protein/macronutrient data.

### Categorization
- Automatically categorizes items into food groups using pattern matching.

### Meal Generation
- Selects meal items based on:
- - Your calorie/protein targets
- - Protein-to-calorie ratio (density)
- - Unfulfilled food groups

### Display & Feedback
- Outputs a breakdown of each meal and how well it meets your goals.

## Sample Output

    PS C:\dinning_hall_meal_prep> ruby tufts_diet_planner.rb
    ===========Tufts Dewick Meal Generator===========
    Generating healthy, balanced meals based on your nutrition goals

    Daily calorie goal: 1666
    Daily protein goal (grams): 72
    Enter date (YYYY-MM-DD): 2025-07-08

    Generating meals for 2025-07-08...
    Fetching breakfast options...
    Fetching lunch options...
    Fetching dinner options...
    ============Meal Plan for 2025-07-08=============
    Daily Goals: 1666 calories, 72g protein

    Breakfast:
    • Hard Cooked Eggs [Protein] (x8)
        640 cal | 56g protein
    • Pineapple Chunks [Fruits]
        22 cal | 0g protein

    Lunch:
    • Green Peas [Veggies] (x9)
        630 cal | 45g protein
    • Marinara Sauce [Condiment] (x2)
        28 cal | 2g protein

    Dinner:
    • Medium Shell Pasta [Grains] (x3)
        513 cal | 18g protein
    • Reese's Pieces [Dessert]
        141 cal | 4g protein

    --------------------------------------------------
    Nutrition Totals:
    Calories: 1974/1666 (118.5%)
    Protein:  125g/72g (173.6%)

    Food Group Checklist:
    ✅ Protein
    ✅ Veggies
    ✅ Fruits
    ✅ Grains
    ❌ Dairy
    --------------------------------------------------
    PS C:\dinning_hall_meal_prep> 

## License

This project is licensed under the MIT License.
