describe CourseLicenseCreator do

  describe '#initialize' do
    let (:course_guid) { SecureRandom.uuid  }
    let (:course_package_ids) { [56, 79]  }

    it 'gets initialzed with the course guid and array of package ids' do
      course_license_creator = CourseLicenseCreator.new(course_guid, course_package_ids)
      expect(course_license_creator.course_guid).to eq(course_guid)
      expect(course_license_creator.course_package_ids).to eq(course_package_ids)
    end


    it 'makes the API call to create the license' do
      allow(Maestro::CourseLicense).to receive(:create).with(course_guid, course_package_ids)
      course_license_creator = CourseLicenseCreator.new(course_guid, course_package_ids)
    end

  end

end
