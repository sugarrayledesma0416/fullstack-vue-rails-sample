describe Cartridge::CartridgeSearcher do
  let(:program) { create(:program) }
  let(:searcher) { described_class.new(program) }

  describe '#cartridges_by_version' do
    it 'returns the cartridges for the specified program, grouped by version' do
      other_program = create(:program)
      create(
        :cartridge_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
        program: other_program
      )
      cartridge_1 = create(
        :cartridge_failed_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_2_0,
        program: program
      )
      cartridge_2 = create(
        :cartridge_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_3_0,
        program: program
      )
      cartridge_3 = create(
        :cartridge_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_2_0,
        program: program
      )
      cartridge_4 = create(
        :cartridge_failed_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_2_0,
        program: program
      )
      cartridge_5 = create(
        :cartridge_failed_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_3_0,
        program: program
      )
      cartridge_6 = create(
        :cartridge_build_status,
        cc_version: MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_3_0,
        program: program
      )

      expect(searcher.cartridges_by_version).to eq(
        MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0 => {
          cartridge: nil,
          last_failed_cartridge: nil
        },
        MultiVersionCommonCartridge::CartridgeVersions::CC_1_2_0 => {
          cartridge: nil,
          last_failed_cartridge: cartridge_1
        },
        MultiVersionCommonCartridge::CartridgeVersions::CC_1_3_0 => {
          cartridge: cartridge_2,
          last_failed_cartridge: nil
        },
        MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_2_0 => {
          cartridge: cartridge_3,
          last_failed_cartridge: cartridge_4
        },
        MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_3_0 => {
          cartridge: cartridge_6,
          last_failed_cartridge: nil
        }
      )
    end

    context 'when no cartridge exists for a CC version,' do
      it 'returns no valid cartridge and no invalid cartridge' do
        expect(
          searcher.cartridges_by_version[
            MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0
          ]
        ).to eq(
          cartridge: nil,
          last_failed_cartridge: nil
        )
      end
    end

    context 'when invalid cartridges exist and no valid cartridge exist,' do
      it 'returns no valid cartridge and the latest invalid cartridge' do
        cartridge_1 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_2 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_3 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )

        expect(
          searcher.cartridges_by_version[
            MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0
          ]
        ).to eq(
          cartridge: nil,
          last_failed_cartridge: cartridge_3
        )
      end
    end

    context 'when the last cartridge is invalid,' do
      it 'returns the latest valid cartridge and the lastest invalid cartridge' do
        cartridge_1 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_2 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_3 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_4 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )

        expect(
          searcher.cartridges_by_version[
            MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0
          ]
        ).to eq(
          cartridge: cartridge_3,
          last_failed_cartridge: cartridge_4
        )
      end
    end

    context 'when the last cartridge is valid,' do
      it 'returns the latest valid cartridge and nil for the latest invalid cartridge' do
        cartridge_1 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_2 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_3 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )

        expect(
          searcher.cartridges_by_version[
            MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0
          ]
        ).to eq(
          cartridge: cartridge_3,
          last_failed_cartridge: nil
        )
      end
    end
  end
end
