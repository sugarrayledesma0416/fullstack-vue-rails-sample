describe RubricUpdater do
  let(:original_xml) do
    <<~XML
      <activity>
        <rubric id="123" rubric_revision_id="456">
          <style>
            <show_score>true</show_score>
          </style>
          <header_row>
            <header_column id="1">old_col_1_header</header_column>
            <header_column id="2">old_col_2_header</header_column>
          </header_row>
          <criteria>
            <title>old_row_1_title</title>
            <performance header_id="1">
              <description>old_row_1_col_1</description>
              <score>1</score>
            </performance>
            <performance header_id="2">
              <description>old_row_1_col_2</description>
              <score>2</score>
            </performance>
          </criteria>
          <criteria>
            <title>old_row_2_title</title>
            <performance header_id="1">
              <description>old_row_2_col_1</description>
              <score>3</score>
            </performance>
            <performance header_id="2">
              <description>old_row_2_col_2</description>
              <score>4</score>
            </performance>
          </criteria>
        </rubric>
      </activity>
    XML
  end

  let(:posted_data) do
    {
      criterias: [
        {
          Criteria: {
            performances: [
              { description: 'new_row_1_col_1', header_id: '1', score: 5 },
              { description: 'new_row_1_col_2', header_id: '2', score: 6 }
            ],
            title: 'new_row_1_title'
          }
        },
        {
          Criteria: {
            performances: [
              { description: 'new_row_2_col_1', header_id: '1', score: 7 },
              { description: 'new_row_2_col_2', header_id: '2', score: 8 }
            ],
            title: 'new_row_2_title'
          }
        }
      ],
      header_row: {
        HeaderRow: {
          header_columns: [
            { id: '1', label: 'new_col_1_header' },
            { id: '2', label: 'new_col_2_header' }
          ]
        }
      },
      show_score: false
    }
  end

  let(:updater) { described_class.new(original_xml, posted_data.to_json) }
  let(:result_doc) { Nokogiri::XML.parse(updater.new_doc.to_xml) }
  let(:rubric_node) { result_doc.at('rubric') }

  def mutate_original_xml
    doc = Nokogiri::XML.parse(original_xml)
    yield doc.root
    doc.to_xml
  end

  describe '#new_doc' do
    it 'returns xml with an activity node at the root' do
      expect(result_doc.root.name).to eq('activity')
    end

    it 'sets the id attr of the rubric node to 0' do
      expect(rubric_node[:id]).to eq('0')
    end

    it 'sets the rubric_revision_id attr of the rubric node to 0' do
      expect(rubric_node[:rubric_revision_id]).to eq('0')
    end

    it 'updates the contents of the header_column nodes based on their ids' do
      header_row_node = rubric_node.at('header_row')
      header_column_nodes = header_row_node.elements

      expect(
        header_column_nodes.map { |node| [node[:id], node.text] }
      ).to contain_exactly(
        %w[1 new_col_1_header],
        %w[2 new_col_2_header]
      )
    end

    it 'updates the title nodes of the criteria nodes based on their order' do
      title_nodes = rubric_node.xpath('criteria/title')

      expect(title_nodes.map(&:text)).to eq(
        %w[new_row_1_title new_row_2_title]
      )
    end

    it 'updates the description nodes of each performance child of the ' \
       'criteria nodes based on criteria order and the header_id attr ' \
       'of the performance node' do
      expect(
        rubric_node.xpath('criteria/performance').map do |node|
          [node[:header_id], node.at('description').text]
        end
      ).to eq(
        [
          %w[1 new_row_1_col_1],
          %w[2 new_row_1_col_2],
          %w[1 new_row_2_col_1],
          %w[2 new_row_2_col_2]
        ]
      )
    end

    it 'translate the new description HTML obtained from Froala ' \
       'into XML entities that can be processed by the activity engine' do
      posted_data[:criterias][0][:Criteria][:performances][0][:description] =
        <<~XML
          <p>First line <strong>of text</strong></p>
          <ol style="list-style-type: lower-roman;">
            <li>Ordered list first <strong>entry</strong></li>
            <li>Ordered list second <em>entry</em></li>
          </ol>
          <ul style="list-style-type: disc;">
            <li>Unordered list first <strong>entry</strong></li>
            <li>Unordered list second <em>entry</em></li>
          </ul>
          <p>Last Line <em>of text</em> with apostrophe’s</p>
        XML
      result_description_node = rubric_node.at_xpath('criteria/performance/description')
      expected_xml = <<~XML
        <description><p>First line <important>of text</important></p>
        <sublist style="lower-roman">
          <li>Ordered list first <important>entry</important></li>
          <li>Ordered list second <emphasis>entry</emphasis></li>
        </sublist>
        <sublist style="bullet">
          <li>Unordered list first <important>entry</important></li>
          <li>Unordered list second <emphasis>entry</emphasis></li>
        </sublist>
        <p>Last Line <emphasis>of text</emphasis> with apostrophe’s</p>
        </description>
      XML
      expected_doc = Nokogiri::XML.parse(expected_xml)
      expect(result_description_node.to_xml).to eq(
        expected_doc.at_xpath('description').to_xml
      )
    end

    it 'translates blank lines generated by Froala into ' \
       'into XML entities that can be processed by the activity engine' do
      posted_data[:criterias][0][:Criteria][:performances][0][:description] =
        <<~XML
          <p>First line<br><strong>of text</strong></p>
          <p><br></p>
          <p><br></p>
          <p><br></p>
          <p>Last Line <em>of text</em></p>
        XML
      result_description_node = rubric_node.at_xpath('criteria/performance/description')
      expected_xml = <<~XML
        <description><p>First line<br/><important>of text</important></p>
        <p>
          <br/>
        </p>
        <p>
          <br/>
        </p>
        <p>
          <br/>
        </p>
        <p>Last Line <emphasis>of text</emphasis></p>
        </description>
      XML
      expected_doc = Nokogiri::XML.parse(expected_xml)
      expect(result_description_node.to_xml).to eq(
        expected_doc.at_xpath('description').to_xml
      )
    end

    it 'maintains the classes of the lists, if they were not modified using Froala' do
      posted_data[:criterias][0][:Criteria][:performances][0][:description] =
        <<~XML
          <p>First line <strong>of text</strong></p>
          <ol class="c-list-reference__list  c-list-reference__list--lower-roman">
            <li>Ordered list first <strong>entry</strong></li>
            <li>Ordered list second <em>entry</em></li>
          </ol>
          <ul class="c-list-reference__list  c-list-reference__list--bullet">
            <li>Unordered list first <strong>entry</strong></li>
            <li>Unordered list second <em>entry</em></li>
          </ul>
          <p>Last Line <em>of text</em></p>
        XML
      result_description_node = rubric_node.at_xpath('criteria/performance/description')
      expected_xml = <<~XML
        <description><p>First line <important>of text</important></p>
        <sublist style="lower-roman">
          <li>Ordered list first <important>entry</important></li>
          <li>Ordered list second <emphasis>entry</emphasis></li>
        </sublist>
        <sublist style="bullet">
          <li>Unordered list first <important>entry</important></li>
          <li>Unordered list second <emphasis>entry</emphasis></li>
        </sublist>
        <p>Last Line <emphasis>of text</emphasis></p>
        </description>
      XML
      expected_doc = Nokogiri::XML.parse(expected_xml)
      expect(result_description_node.to_xml).to eq(
        expected_doc.at_xpath('description').to_xml
      )
    end

    it 'updates the scores for each performance node' do
      expect(
        rubric_node.xpath('criteria/performance').map do |node|
          [node[:header_id], node.at('score').text]
        end
      ).to eq(
        [
          %w[1 5],
          %w[2 6],
          %w[1 7],
          %w[2 8]
        ]
      )
    end

    context 'when adding a column' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'new_row_1_col_1', header_id: '1', score: 5 },
                  { description: 'new_row_1_col_2', header_id: '2', score: 6 },
                  { description: 'new_row_1_col_3', header_id: '3', score: 6 }
                ],
                title: 'new_row_1_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'new_row_2_col_1', header_id: '1', score: 7 },
                  { description: 'new_row_2_col_2', header_id: '2', score: 8 },
                  { description: 'new_row_2_col_3', header_id: '3', score: 7 }
                ],
                title: 'new_row_2_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'new_col_1_header' },
                { id: '2', label: 'new_col_2_header' },
                { id: '3', label: 'new_col_3_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'creates the xml for a new header node' do
        header_row_node = rubric_node.at('header_row')
        header_column_nodes = header_row_node.elements

        expect(
          header_column_nodes.map { |node| [node[:id], node.text] }
        ).to contain_exactly(
          %w[1 new_col_1_header],
          %w[2 new_col_2_header],
          %w[3 new_col_3_header]
        )
      end

      it 'creates the xml for a new description for the new header' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[1 new_row_1_col_1],
            %w[2 new_row_1_col_2],
            %w[3 new_row_1_col_3],
            %w[1 new_row_2_col_1],
            %w[2 new_row_2_col_2],
            %w[3 new_row_2_col_3]
          ]
        )
      end
    end

    context 'when adding a row' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'new_row_1_col_1', header_id: '1', score: 5 },
                  { description: 'new_row_1_col_2', header_id: '2', score: 6 }
                ],
                title: 'new_row_1_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'new_row_2_col_1', header_id: '1', score: 7 },
                  { description: 'new_row_2_col_2', header_id: '2', score: 8 }
                ],
                title: 'new_row_2_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'new_row_3_col_1', header_id: '1', score: 9 },
                  { description: 'new_row_3_col_2', header_id: '2', score: 10 }
                ],
                title: 'new_row_3_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'new_col_1_header' },
                { id: '2', label: 'new_col_2_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'creates the xml for a new criteria node' do
        title_nodes = rubric_node.xpath('criteria/title')

        expect(title_nodes.map(&:text)).to eq(
          %w[new_row_1_title new_row_2_title new_row_3_title]
        )
      end

      it 'creates the xml for new descriptions for the new row' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[1 new_row_1_col_1],
            %w[2 new_row_1_col_2],
            %w[1 new_row_2_col_1],
            %w[2 new_row_2_col_2],
            %w[1 new_row_3_col_1],
            %w[2 new_row_3_col_2]
          ]
        )
      end
    end

    context 'when deleting a column,' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'new_row_1_col_1', header_id: '1', score: 5 },
                ],
                title: 'new_row_1_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'new_row_2_col_1', header_id: '1', score: 7 }
                ],
                title: 'new_row_2_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'new_col_1_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'removes the xml for the deleted header' do
        header_row_node = rubric_node.at('header_row')
        header_column_nodes = header_row_node.elements

        expect(
          header_column_nodes.map { |node| [node[:id], node.text] }
        ).to contain_exactly(
          %w[1 new_col_1_header]
        )
      end

      it 'removes the xml for the performances for the deleted header' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[1 new_row_1_col_1],
            %w[1 new_row_2_col_1]
          ]
        )
      end
    end

    context 'when deleting a row,' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'old_row_1_col_1', header_id: '1', score: 5 },
                  { description: 'old_row_1_col_2', header_id: '2', score: 6 }
                ],
                title: 'old_row_1_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'old_col_1_header' },
                { id: '2', label: 'old_col_2_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'removes the title of the deleted criteria' do
        title_nodes = rubric_node.xpath('criteria/title')

        expect(title_nodes.map(&:text)).to eq(
          %w[old_row_1_title]
        )
      end

      it 'removes the performance nodes for the deleted criteria' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[1 old_row_1_col_1],
            %w[2 old_row_1_col_2]
          ]
        )
      end
    end

    context 'when reordering a column' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'old_row_1_col_2', header_id: '2', score: 6 },
                  { description: 'old_row_1_col_1', header_id: '1', score: 5 }
                ],
                title: 'old_row_1_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'old_row_2_col_2', header_id: '2', score: 8 },
                  { description: 'old_row_2_col_1', header_id: '1', score: 7 }
                ],
                title: 'old_row_2_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '2', label: 'old_col_2_header' },
                { id: '1', label: 'old_col_1_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'updates the orders of the header_column nodes' do
        header_row_node = rubric_node.at('header_row')
        header_column_nodes = header_row_node.elements

        expect(
          header_column_nodes.map { |node| [node[:id], node.text] }
        ).to eq(
          [
            %w[2 old_col_2_header],
            %w[1 old_col_1_header]
          ]
        )
      end

      it 'updates the description nodes of each performance child of the ' \
         'criteria to match the new header order' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[2 old_row_1_col_2],
            %w[1 old_row_1_col_1],
            %w[2 old_row_2_col_2],
            %w[1 old_row_2_col_1]
          ]
        )
      end
    end

    context 'when reordering a row' do
      let(:posted_data) do
        {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'old_row_2_col_1', header_id: '1', score: 7 },
                  { description: 'old_row_2_col_2', header_id: '2', score: 8 }
                ],
                title: 'old_row_2_title'
              }
            },
            {
              Criteria: {
                performances: [
                  { description: 'old_row_1_col_1', header_id: '1', score: 5 },
                  { description: 'old_row_1_col_2', header_id: '2', score: 6 }
                ],
                title: 'old_row_1_title'
              }
            }
          ],
          header_row: {
            HeaderRow: {
              header_columns: [
                { id: '1', label: 'old_col_1_header' },
                { id: '2', label: 'old_col_2_header' }
              ]
            }
          },
          show_score: false
        }
      end

      it 'updates the orders of the criteria title nodes' do
        title_nodes = rubric_node.xpath('criteria/title')

        expect(title_nodes.map(&:text)).to eq(
          %w[old_row_2_title old_row_1_title]
        )
      end

      it 'updates the description nodes of each performance child of the ' \
         'criteria to match the new row order' do
        expect(
          rubric_node.xpath('criteria/performance').map do |node|
            [node[:header_id], node.at('description').text]
          end
        ).to eq(
          [
            %w[1 old_row_2_col_1],
            %w[2 old_row_2_col_2],
            %w[1 old_row_1_col_1],
            %w[2 old_row_1_col_2]
          ]
        )
      end
    end

    context 'when the original xml has a show_score node set to true' do
      it 'leaves the show_score value set to true even if a false show_score ' \
         'value is posted' do
        # show_score will always be forced to true no matter what is posted
        posted_data[:show_score] = false

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end

      it 'leaves the show_score value set to true if a true show_score ' \
         'value is posted' do
        posted_data[:show_score] = true

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end
    end

    context 'when the original xml has a show_score node set to false' do
      let(:new_xml) do
        mutate_original_xml { |doc| doc.at('show_score').content = 'false' }
      end

      let(:updater) { described_class.new(new_xml, posted_data.to_json) }

      it 'updates the show_score value to true even if a false show_score ' \
         'value is posted' do
        # show_score will always be forced to true no matter what is posted
        posted_data[:show_score] = false

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end

      it 'updates the show_score value to true if a true show_score ' \
         'value is posted' do
        posted_data[:show_score] = true

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end
    end

    context 'when the original xml has no show_score node' do
      let(:new_xml) do
        mutate_original_xml { |doc| doc.at('style').unlink }
      end

      let(:updater) { described_class.new(new_xml, posted_data.to_json) }

      it 'creates a show_score node with a true value even if a false show_score ' \
         'value is posted' do
        # show_score will always be forced to true no matter what is posted
        posted_data[:show_score] = false

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end

      it 'creates a show_score node with a true value if a true show_score ' \
         'value is posted' do
        posted_data[:show_score] = true

        expect(rubric_node.at('style/show_score').text).to eq('true')
      end
    end
  end
end
