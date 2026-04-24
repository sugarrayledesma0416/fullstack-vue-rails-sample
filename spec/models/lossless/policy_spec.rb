describe Lossless::Policy do
  describe '#token' do
    let(:user) { build_stubbed(:student) }
    let(:cache_key) { 'abcdefg' }
    let(:client) do
      instance_double(Lossless::Client, get_token: '', send_policy: '')
    end

    before do
      allow(Lossless::Client).to receive(:new).and_return(client)
    end

    it 'instantiates a Lossless::Client instance' do
      described_class.new(cache_key, user).token

      expect(Lossless::Client).to have_received(:new)
    end

    it 'asks the client for a token for the specified cache_key' do
      described_class.new(cache_key, user).token

      expect(client).to have_received(:get_token).with(cache_key)
    end

    it 'returns the token if the client returns one' do
      existing_token = 'defghi'
      allow(client).to receive(:get_token).and_return(existing_token)

      result = described_class.new(cache_key, user).token
      expect(result).to eq(existing_token)
    end

    context 'when the client returns an empty token,' do
      before do
        allow(client).to receive(:get_token).and_return('')
      end

      it "sends the client a policy with the specified user's guid and the " \
         'specified cache_key' do
        described_class.new(cache_key, user).token

        expect(client).to have_received(:send_policy).with(
          hash_including(
            cache_key: cache_key,
            user_guid: user.guid
          )
        )
      end

      context 'when current user is a student,' do
        let(:user) { build_stubbed(:student) }
        let(:section_1) { build_stubbed(:section) }
        let(:section_2) { build_stubbed(:section) }

        before do
          allow(user).to receive(:active_sections).and_return(
            [section_1, section_2]
          )
        end

        context 'when the user has no active sections' do
          before do
            allow(user).to receive(:active_sections).and_return(
              []
            )
          end

          it 'sends a policy letting the user only play his own recording' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                read_policy: {
                  any: [
                    metadata: { user_guid: user.guid }
                  ]
                }
              )
            )
          end

          it 'sends a policy letting the user record only recordings matching ' \
             'their user id and in the section zero' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                write_policy: {
                  all: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: ['0'] } }
                  ]
                }
              )
            )
          end
        end

        it 'sends the client a policy with user type of "Student"' do
          described_class.new(cache_key, user).token

          expect(client).to have_received(:send_policy).with(
            hash_including(user_type: 'Student')
          )
        end

        it 'sends a policy letting the user play their own recordings' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              read_policy: {
                any: array_including(
                  metadata: { user_guid: user.guid }
                )
              }
            )
          )
        end

        it 'sends a policy letting the user play the recording of their ' \
           'instructors in the section he is enrolled in' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              read_policy: {
                any: array_including(
                  metadata: {
                    user_guid: [section_1.instructor.guid, section_2.instructor.guid],
                    section_guid: [section_1.guid, section_2.guid]
                  }
                )
              }
            )
          )
        end

        it 'sends a policy letting the user record only recordings matching ' \
           'their user id and in a section to which they are enrolled and in section zero' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              write_policy: {
                all: [
                  { metadata: { user_guid: user.guid } },
                  {
                    metadata: {
                      section_guid: [section_1.guid, section_2.guid, '0']
                    }
                  }
                ]
              }
            )
          )
        end
      end

      context 'when current user is an instructor,' do
        let(:user) { create(:instructor) }
        let(:course) { create(:course) }
        let(:section_1) { create(:section, instructor: user) }
        let(:section_instructor_1) { section_1.section_instructors.first }

        before do
          create(:section_without_section_instructor_callback, instructor: user, course: course)

          # Needed because section factory creates section_instructor records
          # in after(:create) but doesn't update the collection proxy.
          section_1.section_instructors.reload
        end

        it 'sends the client a policy with user type of "Instructor"' do
          described_class.new(cache_key, user).token

          expect(client).to have_received(:send_policy).with(
            hash_including(user_type: 'Instructor')
          )
        end

        it 'sends a policy letting the user play their own recordings' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              read_policy: {
                any: array_including(
                  metadata: { user_guid: user.guid }
                )
              }
            )
          )
        end

        it 'sends a policy letting the user play all the recordings from ' \
           'all the sections for which they are an instructor' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              read_policy: {
                any: array_including(
                  metadata: {
                    section_guid: [section_instructor_1.section.guid]
                  }
                )
              }
            )
          )
        end

        it 'sends a policy letting the user record only recordings for ' \
           'sections for which they are an instructor and for section zero' do
          described_class.new(cache_key, user).token
          expect(client).to have_received(:send_policy).with(
            hash_including(
              write_policy: {
                all: [
                  { metadata: { user_guid: user.guid } },
                  { metadata: { section_guid: [section_instructor_1.section.guid, '0'] } }
                ]
              }
            )
          )
        end

        context 'when the instructor has archived section_instructor ' \
                'records pointing to unarchived sections,' do
          before do
            section_3 = create(:section, instructor: user)
            section_3.section_instructors.reload.update_all(is_archived: true)
          end

          it 'does not throw an error' do
            expect do
              described_class.new(cache_key, user).token
            end.not_to raise_error
          end

          it 'sends a policy letting the user play all his recording, all ' \
             'the recording for which they are an instructor, ignoring the ' \
             'sections with archived section_instructor records' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                read_policy: {
                  any: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: [section_instructor_1.section.guid] } }
                  ]
                }
              )
            )
          end

          it 'sends a policy letting the user record recordings for sections ' \
             'for which they are an instructor, ignoring the sections with ' \
             'archived section_instructor records, and for section zero' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                write_policy: {
                  all: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: [section_instructor_1.section.guid, '0'] } }
                  ]
                }
              )
            )
          end
        end

        context 'when the instructor has archived section_instructor ' \
                'records pointing to archived sections,' do
          before do
            section_3 = create(:section, instructor: user, is_archived: true)
            section_3.section_instructors.reload.update_all(is_archived: true)
          end

          it 'does not throw an error' do
            expect do
              described_class.new(cache_key, user).token
            end.not_to raise_error
          end

          it 'sends a policy letting the user play all his recording, all ' \
             'the recording for which they are an instructor, ignoring the ' \
             'archived sections' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                read_policy: {
                  any: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: [section_instructor_1.section.guid] } }
                  ]
                }
              )
            )
          end

          it 'sends a policy letting the user record recordings for sections ' \
             'for which they are an instructor, ignoring the archived sections, ' \
             'and for section zero' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                write_policy: {
                  all: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: [section_instructor_1.section.guid, '0'] } }
                  ]
                }
              )
            )
          end
        end

        context 'when the instructor only has archived section_instructor ' \
                'records pointing to archived sections,' do
          before do
            section_1.section_instructors.reload.update_all(is_archived: true)
          end

          it 'does not throw an error' do
            expect do
              described_class.new(cache_key, user).token
            end.not_to raise_error
          end

          it 'sends a policy letting the user play all his recording' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                read_policy: {
                  any: [
                    metadata: { user_guid: user.guid }
                  ]
                }
              )
            )
          end

          it 'sends a policy letting the user record recordings only for ' \
             'section zero' do
            described_class.new(cache_key, user).token
            expect(client).to have_received(:send_policy).with(
              hash_including(
                write_policy: {
                  all: [
                    { metadata: { user_guid: user.guid } },
                    { metadata: { section_guid: ['0'] } }
                  ]
                }
              )
            )
          end
        end
      end
    end
  end
end
