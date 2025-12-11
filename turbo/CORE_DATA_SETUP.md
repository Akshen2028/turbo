# Core Data Model Setup

To enable custom categories, you need to add the following entities to your Core Data model (`turbo.xcdatamodeld`):

## Entity 1: CustomCategoryEntity

**Attributes:**
- `id` (UUID, Optional = NO, Default Value: `00000000-0000-0000-0000-000000000000`)
  - Note: This is just a placeholder. The actual UUID will be set in code when creating the entity.
- `name` (String, Optional = NO, Default Value: `""`)
- `createdAt` (Date, Optional = NO, Default Value: `$now()` or current date/time)

**Relationships:**
- `questions` (To Many, Destination: SavedQuestionEntity, Inverse: category)

## Entity 2: SavedQuestionEntity

**Attributes:**
- `id` (UUID, Optional = NO, Default Value: `00000000-0000-0000-0000-000000000000`)
  - Note: This is just a placeholder. The actual UUID will be set in code when creating the entity.
- `question` (String, Optional = NO, Default Value: `""`)
- `createdAt` (Date, Optional = NO, Default Value: `$now()` or current date/time)

**Relationships:**
- `category` (To One, Destination: CustomCategoryEntity, Inverse: questions)

## Default Value Notes:

- **UUID**: Use `00000000-0000-0000-0000-000000000000` as a placeholder. The actual UUID is always set in code when creating entities.
- **String**: Use empty string `""` as default.
- **Date**: In Xcode's Core Data editor, you can set the default value expression to `$now()` or manually set it to the current date. However, we also set this in code, so it's mainly a safety net.

## Steps to Add in Xcode:

1. Open `turbo.xcdatamodeld` in Xcode
2. Click the "+" button to add a new entity
3. Name it "CustomCategoryEntity"
4. Add the attributes listed above
5. **IMPORTANT**: Add a relationship named **"questions"** (exactly this name):
   - Click the "+" under Relationships
   - Name: `questions`
   - Destination: `SavedQuestionEntity`
   - Type: To Many
   - Inverse: `category`
6. Repeat for SavedQuestionEntity:
   - Add the attributes listed above
   - Add a relationship named **"category"** (exactly this name):
     - Click the "+" under Relationships
     - Name: `category`
     - Destination: `CustomCategoryEntity`
     - Type: To One
     - Inverse: `questions`
7. **CRITICAL**: Make sure the inverse relationships are set correctly:
   - CustomCategoryEntity.questions → inverse: SavedQuestionEntity.category
   - SavedQuestionEntity.category → inverse: CustomCategoryEntity.questions
8. Make sure "Codegen" is set to "Class Definition" or "Category/Extension" for both entities
9. **Clean and rebuild** after adding the entities

The entity classes (`CustomCategoryEntity.swift` and `SavedQuestionEntity.swift`) have already been created and should work once the Core Data model is updated.

