variable "name" {
  description = "Name of the CodePipeline"
  type        = string
  default     = ""
}
variable "role_arn" {
  description = "IAM role ARN for the CodePipeline"
  type        = string
  default     = ""
}
variable "artifact_bucket" {
  description = "S3 bucket for storing artifacts"
  type        = string
  default     = ""
}
variable "artifact_store_type" {
  description = "Type of artifact store (e.g., S3)"
  type        = string
  default     = ""
}
variable "stages" {
  description = "Stages of the CodePipeline"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = list(string)
      output_artifacts = list(string)
      configuration    = map(string)
    }))
  }))
  default = [
    {
      name = "Source"
      actions = [
        {
          name             = "SourceAction"
          category         = "Source"
          owner            = "AWS"
          provider         = "CodeCommit"
          version          = "1"
          input_artifacts  = []
          output_artifacts = ["SourceOutput"]
          configuration    = { RepositoryName = "example-repo", BranchName = "main" }
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "BuildAction"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["SourceOutput"]
          output_artifacts = ["BuildOutput"]
          configuration    = { ProjectName = "example-build-project" }
        }
      ]
    }
  ]

}
