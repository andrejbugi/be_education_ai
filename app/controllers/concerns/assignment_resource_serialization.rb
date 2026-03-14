module AssignmentResourceSerialization
  private

  def serialize_assignment_resource(resource)
    attached_file_url = assignment_resource_file_url(resource)

    {
      id: resource.id,
      title: resource.title,
      resource_type: resource.resource_type,
      file_url: attached_file_url || resource.file_url,
      external_url: resource.external_url,
      embed_url: resource.embed_url,
      description: resource.description,
      position: resource.position,
      is_required: resource.is_required,
      metadata: resource.metadata,
      uploaded_file: serialize_uploaded_file(resource, attached_file_url)
    }
  end

  def serialize_uploaded_file(resource, attached_file_url = nil)
    return nil unless resource.file.attached?

    blob = resource.file.blob
    {
      filename: blob.filename.to_s,
      byte_size: blob.byte_size,
      content_type: blob.content_type,
      url: attached_file_url || assignment_resource_file_url(resource)
    }
  end

  def assignment_resource_file_url(resource)
    return nil unless resource.file.attached?

    rails_blob_url(resource.file, host: request.base_url)
  end
end
