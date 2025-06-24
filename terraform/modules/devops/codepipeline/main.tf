# CodePipeline Configuration
resource "aws_codepipeline" "carshub_pipeline" {
  name     = var.name
  role_arn = var.role_arn

  artifact_store {
    location = var.artifact_bucket
    type     = var.artifact_store_type
  }
  dynamic "stage" {
    for_each = var.stages
    content {
      name = stage.value.name
      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts

          configuration = {
            for k, v in action.value.configuration : k => v
          }
        }
      }
    }    
  }
}
