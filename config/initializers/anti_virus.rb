require_relative '../../app/middleware/scan_uploads'

# Add virus-scan upload
Rails.configuration.middleware.use ScanUploads
