class RecipesController < ApplicationController
  PER_PAGE = 15

  def index
    serialized_recipes = ActiveModel::Serializer::CollectionSerializer
      .new(recipes, serializer: RecipeSerializer)
    render json: { data: serialized_recipes, meta: { total_pages: recipes.total_pages } }
  end

  def recipes
    @recipes ||= begin
      ingredients_pattern = (recipe_params[:ingredients] || []).map { |name| "%#{name}%" }
      Recipe
        .joins(:ingredients)
        .where(ingredients_pattern.map { "ingredients.name LIKE ?" }.join(" OR "), *ingredients_pattern)
        .group("recipes.id")
        .having("COUNT(DISTINCT ingredients.name) = ?", ingredients_pattern.size)
        .page(page)
        .per(PER_PAGE)
    end
  end

  private

  def recipe_params
    params.permit(ingredients: [])
  end

  def page
    params[:page].to_i || 1
  end

  def meta
    { total_pages: recipes.count / PER_PAGE }
  end
end
