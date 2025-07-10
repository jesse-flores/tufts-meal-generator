=begin
tufts_diet_planner.rb
Author: Jesse Flores (jflore12)
Date: 2025-07-08
Purpouse: This Ruby script fetches meal options from the Tufts Dewick Dining API,
              categorizes them, and generates a balanced meal plan for the user.
              It allows users to set their daily calorie and protein goals,
              select a date, and generates meals for breakfast, lunch, and dinner.
              The meals are selected based on nutritional content and user preferences.
=end

require 'json'
require 'open-uri'
require 'date'
require 'set'
require 'tty-prompt'

class TuftsMealGenerator
  # Base URL for the Tufts Dewick Dining API
  BASE_URL = "https://tufts.api.nutrislice.com/menu/api/weeks/school/dewick-dining/menu-type"
  CATEGORIES = ['Protein', 'Veggies', 'Fruits', 'Grains', 'Dairy'].freeze
  MAX_ITEM_QUANTITY = 3 # Maximum quantity allowed for a single item

=begin
Name: initialize
Purpouse: Initializes the TuftsMealGenerator instance
Parameters: None
Returns: None
Effects: Sets up the initial state of the meal generator,
          including the prompt, selected date, user goals,
          generated meals, and fulfilled categories.
=end
  def initialize
    @prompt = TTY::Prompt.new
    @selected_date = Date.today
    @user_goals = { calories: 2000, protein: 100 }
    @generated_meals = { breakfast: [], lunch: [], dinner: [] }
    @fulfilled_categories = Set.new
  end

=begin
Name: run
Purpouse: Starts the meal generation process
Parameters: None
Returns: None
Effects: Calls methods to display a welcome message,
          set user goals, select a date, generate meals,
          and display the meal plan.
=end
  def run
    welcome_message
    set_user_goals
    select_date
    generate_meals
    display_meal_plan
  end

  private

=begin
Name: welcome_message
Purpouse: Displays a welcome message to the user
Parameters: None
Returns: None
Effects: Prints a centered welcome message with the application title
          and a brief description of its purpose.
=end
  def welcome_message
    puts "Tufts Dewick Meal Generator".center(50, '=')
    puts "Generating healthy, balanced meals based on your nutrition goals\n\n"
  end

=begin
Name: set_user_goals
Purpouse: Prompts the user to set their daily calorie and protein goals
Parameters: None
Returns: None
Effects: Uses TTY::Prompt to ask the user for their daily calorie and protein goals,
          with default values of 2000 calories and 100 grams of protein.
          The input is converted to integers and stored in the @user_goals hash.
=end
  def set_user_goals
    @user_goals[:calories] = @prompt.ask("Daily calorie goal:", default: "2000").to_i
    @user_goals[:protein] = @prompt.ask("Daily protein goal (grams):", default: "100").to_i
  end

=begin
Name: select_date
Purpouse: Prompts the user to select a date for meal generation
Parameters: None
Returns: None
Effects: Uses TTY::Prompt to ask the user for a date in the format YYYY-MM-DD,
          with a default value of today's date. The input is validated and converted
          to a Date object, which is stored in @selected_date.
=end
  def select_date
    @selected_date = @prompt.ask("Enter date (YYYY-MM-DD):", default: Date.today.to_s) do |q|
      q.validate(/\d{4}-\d{2}-\d{2}/, "Invalid date format")
      q.convert ->(input) { Date.parse(input) }
    end
  end

=begin
Name: generate_meals
Purpouse: Generates meals for the selected date based on user goals
Parameters: None
Returns: None
Effects: Iterates through each meal type (breakfast, lunch, dinner),
          fetches meal data from the Tufts Dewick Dining API,
          filters out items with no nutrition data,
          sorts items by protein density, and selects items based on nutrition goals.
          The selected meals are stored in the @generated_meals hash.
=end
  def generate_meals
    puts "\nGenerating meals for #{@selected_date}..."

    # Iterate through each meal type (breakfast, lunch, dinner)
    # Fetch meal data from the Tufts Dewick Dining API
    ['breakfast', 'lunch', 'dinner'].each do |meal|
      puts "  Fetching #{meal} options..."
      meal_data = fetch_meal_data(meal)
      next if meal_data.empty?
      
      # Filter out items with no nutrition data
      # This ensures we only work with items that have valid nutritional information
      valid_items = meal_data.select { |item| item[:nutrition][:calories].positive? }
      next if valid_items.empty?
      
      # Sort items by protein density and select based on nutrition goals
      @generated_meals[meal.to_sym] = select_items_for_meal(valid_items)
    end
  end

=begin
Name: fetch_meal_data
Purpouse: Fetches meal data from the Tufts Dewick Dining API for a specific
Parameters: meal_type (String) - The type of meal to fetch (breakfast, lunch, dinner)
Returns: Array of meal items with their nutritional information
Effects: Makes an HTTP request to the API, parses the JSON response,
          and processes the menu items to extract relevant details.
          Returns an empty array if an error occurs or no data is found.
=end
  def fetch_meal_data(meal_type)
    # Looks at Dewick (nutrislice) API
    url = "#{BASE_URL}/#{meal_type}/#{@selected_date.year}/#{@selected_date.month}/#{@selected_date.day}/"
    begin
      response = URI.open(url, "User-Agent" => "Mozilla/5.0", "Accept" => "application/json")
      data = JSON.parse(response.read)
      process_menu_items(data)
    rescue
      [] # Fail on error for simplicity
    end
  end

=begin
Name: process_menu_items
Purpouse: Processes the menu items from the API response
Parameters: data (Hash) - The parsed JSON data from the API response
Returns: Array of processed menu items with their nutritional information
Effects: Extracts food details, nutrition data, and categorizes each item.
=end
  def process_menu_items(data)
    return [] unless data['days'] # Check if 'days' key exists
    matching_day = data['days'].find { |day| day['date'] == @selected_date.to_s } # Find the matching day
    return [] unless matching_day && matching_day['menu_items'] # Check if 'menu_items' key exists

    matching_day['menu_items'].map do |item| # Map through each menu item
      food = item['food'] || {} # Extract food details, default to empty hash if missing
      nutrition_data = food['rounded_nutrition_info'] || {} # Extract nutrition data
      food_name = food['name'] || "Unnamed" # Get the food name, default to "Unnamed" if missing

      { # Create a hash for each food item with its details
        name: food_name,
        description: food['description'] || "",
        category: get_category(food_name), # Assign a category
        nutrition: { # Extract nutritional information, defaulting to 0 if missing
          calories: nutrition_data['calories']&.to_i || 0,
          protein: nutrition_data['g_protein']&.to_i || 0 #, # Uncomment when working with carbs and fat
          # carbs: nutrition_data['g_carbs']&.to_i || 0, # Uncomment when working with carbs
          # fat: nutrition_data['g_fat']&.to_i || 0 # Uncomment when working with fat
        } # Ensure nutrition data is always present
      }
    end.uniq { |item| item[:name] } # Remove duplicates based on name
  end


=begin
Name: get_category
Purpouse: Determines the category of a food item based on its name
Parameters: name (String) - The name of the food item
Returns: String - The category of the food item (e.g., Protein, Veggies, Fruits, Grains, and Misc)
=end
  # ChatGPT was used to create the category elements based on all the food menu items from 7/7/25 to 7/9/25
  def get_category(name)
    name_down = name.downcase # Convert name to lowercase for matching

    case
    when name_down.match?(/egg|sausage|bacon|chicken|ham|tofu|pork|beef|fish|turkey|meatball|burger|crumbles|piccata|meatloaf|shrimp|pollock|thigh|breast|pepperoni|chorizo|steak|willy|moroccan|seitan/)
      'Protein'
    when name_down.match?(/potato|tomato|broccoli|spinach|pepper|onion|veggie|vegetable|salad|greens|carrot|kale|chard|pea|bean|zucchini|squash|cucumber|cauliflower|mint|lettuce|snow pea/)
      'Veggies'
    when name_down.match?(/apple|banana|berry|orange|grape|fruit|pineapple|pear|raisin|melon|grapefruit|blueberry|coconut|apricot|cherry/)
      'Fruits'
    when name_down.match?(/pancake|waffle|bread|oat|cereal|muffin|bagel|grain|rice|quinoa|toast|croissant|pasta|linguini|shell|noodle|risotto|orzo|barley/)
      'Grains'
    when name_down.match?(/milk|cheese|yogurt/)
      'Dairy'
    else
      'Misc' # Everything else
    end
  end
  
  
  
=begin
Name: select_items_for_meal
Purpouse: Selects food items for a meal based on nutritional goals
Parameters: items (Array) - Array of food items with their nutritional information
Returns: Array of selected food items for the meal
Effects: 
  1. Sorts items prioritizing unfulfilled categories and protein density
  2. Selects items until reaching 90% of the target calories (1/3 of daily goal)
  3. Limits each item to a maximum of 3 servings
  4. Marks categories as fulfilled when first adding an item from that category
  5. Maintains calorie total between 90-110% of target for balanced meal size
=end
def select_items_for_meal(items)
  target_cals = (@user_goals[:calories] / 3.0).round
  sorted_items = items.sort_by do |item|
    is_needed = !@fulfilled_categories.include?(item[:category]) && item[:category] != 'Misc'
    [is_needed ? 0 : 1, -protein_ratio(item)]
  end

  selected = []
  current_cals = 0
  item_counts = Hash.new(0)
  # Initialize item counts to track how many of each item we have selected
  # item_counts = { "Grilled Chicken" => 2, "Broccoli" => 1 }

  sorted_items.each do |item|
    break if current_cals >= target_cals * 0.9 # Stop when we reach 90% of target

    current_count = item_counts[item[:name]]
    # Skip if we already have 3 of this item


    next if current_count >= MAX_ITEM_QUANTITY
    # Skip if adding this item would exceed 120% of the target calories

    remaining_quantity = MAX_ITEM_QUANTITY - current_count
    # Calculate how many more of this item we can add without exceeding target calories
    possible_additions = [ remaining_quantity, ((target_cals * 1.1 - current_cals) / item[:nutrition][:calories]).floor].min
    # If we can add more of this item, do so

    if possible_additions > 0
      additions_to_make = [possible_additions, 3 - current_count].min
      additions_to_make.times do
        selected << item
        current_cals += item[:nutrition][:calories]
        item_counts[item[:name]] += 1
        @fulfilled_categories.add(item[:category]) if current_count == 0 && item[:category] != 'Misc'
      end
    end
  end

  selected
end

=begin
Name: protein_ratio
Purpouse: Calculates the protein density of a food item
Parameters: item (Hash) - A food item with its nutritional information
Returns: Float - The protein density (protein per calorie) of the item
Effects: Returns 0 if calories are zero to avoid division by zero errors.
=end
  def protein_ratio(item)
    protein = item[:nutrition][:protein].to_f # Get protein content
    calories = [item[:nutrition][:calories].to_f, 1].max # Avoids division by zero
    protein / calories # Calculate protein density (protein per calorie)
  end

=begin
Name: can_add_item?
Purpouse: Checks if an item can be added to the selected items without exceeding calorie limits
Parameters: item (Hash) - The food item being considered for addition
            selected_items (Array) - The currently selected items for the meal
            target_cals (Integer) - The target calorie limit for the meal
Returns: Boolean - True if the item can be added, false otherwise
Effects: Ensures that adding the item does not exceed 120% of the target calories.
          Skips items with zero calories to avoid unnecessary calculations.
=end
  def can_add_item?(item, selected_items, target_cals)
    current_cals = selected_items.sum { |i| i[:nutrition][:calories] } # Calculate current calories from selected items
    item_cals = item[:nutrition][:calories] # Get calories of the item being considered
    return false if item_cals.zero? # Skip items with zero calories
    (current_cals + item_cals) <= target_cals * 1.2 # Check if adding this item exceeds 120% of the target calories
  end

=begin
Name: display_meal_plan
Purpouse: Displays the generated meal plan for the selected date
Parameters: None
Returns: None
Effects: Prints the meal plan with each meal's items, their nutritional information,
          and the total nutrition for the day. It also displays a checklist of fulfilled food categories.
=end
  def display_meal_plan
    puts "Meal Plan for #{@selected_date}".center(50, '=')
    puts "Daily Goals: #{@user_goals[:calories]} calories, #{@user_goals[:protein]}g protein\n"

    total_nutrition = { calories: 0, protein: 0, carbs: 0, fat: 0 }

    # Display each meal with its items and nutritional information
    @generated_meals.each do |meal, items|
      next if items.empty?
      puts "\n#{meal.to_s.capitalize}:"
      
      # Group items by name to handle duplicates
      # This allows us to display the quantity of each item
      item_counts = items.group_by { |item| item[:name] }
      item_counts.each do |name, item_group|
        quantity = item_group.size
        item_sample = item_group.first
        nutrition = item_sample[:nutrition]
        category_tag = "[#{item_sample[:category]}]"

        # Display item name, category, quantity, and nutritional information
        puts "  • #{name} #{category_tag}#{" (x#{quantity})" if quantity > 1}"
        puts "    #{nutrition[:calories] * quantity} cal | #{nutrition[:protein] * quantity}g protein"
      end

      # Update total nutrition for the day
      items.each do |item|
        item[:nutrition].each { |key, value| total_nutrition[key] += value }
      end
    end

    # Display total nutrition for the day
    display_totals(total_nutrition)
  end

=begin
Name: display_totals
Purpouse: Displays the total nutritional values for the day
Parameters: totals (Hash) - A hash containing total nutritional values for the day
Returns: None
Effects: Prints the total calories and protein consumed, along with the percentage of the daily goal achieved.
          It also displays a checklist of fulfilled food categories.
=end
  def display_totals(totals)
    puts "\n" + "-"*50
    puts "Nutrition Totals:"
    puts "  Calories: #{totals[:calories]}/#{@user_goals[:calories]} (#{percentage(totals[:calories], @user_goals[:calories])}%)"
    puts "  Protein:  #{totals[:protein]}g/#{@user_goals[:protein]}g (#{percentage(totals[:protein], @user_goals[:protein])}%)"
    
    # Display the fulfilled food categories
    puts "\nFood Group Checklist:"
    CATEGORIES.each do |category|
        status = @fulfilled_categories.include?(category) ? "✅" : "❌"
        puts "  #{status} #{category}"
    end
    # Display a separator line
    puts "-"*50
  end

=begin
Name: percentage
Purpouse: Calculates the percentage of a value relative to a goal
Parameters: actual (Numeric) - The actual value achieved
#            goal (Numeric) - The target goal value
Returns: Float - The percentage of actual value relative to the goal, rounded to one decimal place
Effects: Returns 0 if the goal is zero to avoid division by zero errors.
=end
  def percentage(actual, goal)
    return 0 if goal.zero?
    (actual.to_f / goal * 100).round(1)
  end
end

# Create an instance of the TuftsMealGenerator and run the application
generator = TuftsMealGenerator.new
generator.run