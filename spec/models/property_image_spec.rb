require 'rails_helper'

RSpec.describe PropertyImage, type: :model do
  let(:user) { create(:user) }
  let(:property) { create(:property, user: user) }

  describe 'associations' do
    it { should belong_to(:property) }
    it { should have_one_attached(:image) }
  end

  describe 'validations' do
    subject { build(:property_image, property: property) }

    it { should validate_presence_of(:property) }
    it { should validate_numericality_of(:position).is_greater_than_or_equal_to(0).allow_nil }

    context 'when using Active Storage' do
      it 'validates presence of attached image' do
        property_image = build(:property_image, property: property)
        expect(property_image).not_to be_valid
        expect(property_image.errors[:image]).to include("can't be blank")
      end

      it 'validates image content type' do
        property_image = build(:property_image, property: property)
        property_image.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test.txt')),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
        expect(property_image).not_to be_valid
        expect(property_image.errors[:image]).to include('must be an image file')
      end

      it 'validates image file size' do
        property_image = build(:property_image, property: property)
        # Simulate a large file by stubbing the byte_size method
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(11.megabytes)

        property_image.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
          filename: 'large_image.jpg',
          content_type: 'image/jpeg'
        )
        expect(property_image).not_to be_valid
        expect(property_image.errors[:image]).to include('file size must be less than 10MB')
      end
    end
  end

  describe 'scopes' do
    let!(:image1) { create(:property_image, property: property, position: 2) }
    let!(:image2) { create(:property_image, property: property, position: 1) }
    let!(:image3) { create(:property_image, property: property, position: nil) }

    describe '.ordered' do
      it 'orders by position first, then created_at' do
        expect(PropertyImage.ordered).to eq([image2, image1, image3])
      end
    end

    describe '.primary' do
      it 'returns the first image in order' do
        expect(PropertyImage.primary).to eq(image2)
      end
    end
  end

  describe 'callbacks' do
    describe '#set_default_position' do
      context 'when position is not set' do
        it 'sets position to the next available number' do
          create(:property_image, property: property, position: 0)
          create(:property_image, property: property, position: 1)

          new_image = build(:property_image, property: property, position: nil)
          new_image.save!

          expect(new_image.position).to eq(2)
        end

        it 'sets position to 0 when no other images exist' do
          new_image = build(:property_image, property: property, position: nil)
          new_image.save!

          expect(new_image.position).to eq(0)
        end
      end

      context 'when position is already set' do
        it 'does not change the position' do
          new_image = build(:property_image, property: property, position: 5)
          new_image.save!

          expect(new_image.position).to eq(5)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:property_image) { create(:property_image, property: property, position: 1) }

    describe '#primary?' do
      it 'returns true for the first image (position 0)' do
        primary_image = create(:property_image, property: property, position: 0)
        expect(primary_image.primary?).to be true
      end

      it 'returns false for non-primary images' do
        expect(property_image.primary?).to be false
      end
    end

    describe '#image_url' do
      context 'when image is attached' do
        it 'returns the URL of the attached image' do
          property_image.image.attach(
            io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
            filename: 'test_image.jpg',
            content_type: 'image/jpeg'
          )

          expect(property_image.image_url).to be_present
          expect(property_image.image_url).to include('test_image.jpg')
        end
      end

      context 'when no image is attached' do
        it 'returns nil' do
          expect(property_image.image_url).to be_nil
        end
      end
    end

    describe '#image_variants' do
      before do
        property_image.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
          filename: 'test_image.jpg',
          content_type: 'image/jpeg'
        )
      end

      it 'returns thumbnail variant URL' do
        expect(property_image.image_variants[:thumbnail]).to be_present
      end

      it 'returns medium variant URL' do
        expect(property_image.image_variants[:medium]).to be_present
      end

      it 'returns large variant URL' do
        expect(property_image.image_variants[:large]).to be_present
      end
    end
  end

  describe 'class methods' do
    describe '.reorder_images' do
      let!(:image1) { create(:property_image, property: property, position: 0) }
      let!(:image2) { create(:property_image, property: property, position: 1) }
      let!(:image3) { create(:property_image, property: property, position: 2) }

      it 'reorders images based on provided positions' do
        new_order = [image3.id, image1.id, image2.id]
        PropertyImage.reorder_images(new_order)

        expect(image3.reload.position).to eq(0)
        expect(image1.reload.position).to eq(1)
        expect(image2.reload.position).to eq(2)
      end

      it 'handles non-existent image IDs gracefully' do
        new_order = [image1.id, 99999, image2.id]
        expect { PropertyImage.reorder_images(new_order) }.not_to raise_error

        expect(image1.reload.position).to eq(0)
        expect(image2.reload.position).to eq(1)
      end
    end

    describe '.bulk_create_from_uploads' do
      let(:upload_files) do
        [
          fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg'),
          fixture_file_upload('spec/fixtures/files/test_image2.jpg', 'image/jpeg')
        ]
      end

      it 'creates multiple property images from uploaded files' do
        expect {
          PropertyImage.bulk_create_from_uploads(property, upload_files)
        }.to change(PropertyImage, :count).by(2)

        images = property.property_images.ordered
        expect(images.first.position).to eq(0)
        expect(images.last.position).to eq(1)
      end

      it 'attaches files to created images' do
        PropertyImage.bulk_create_from_uploads(property, upload_files)

        images = property.property_images.ordered
        expect(images.first.image).to be_attached
        expect(images.last.image).to be_attached
      end
    end
  end

  describe 'drag and drop functionality' do
    let!(:image1) { create(:property_image, property: property, position: 0) }
    let!(:image2) { create(:property_image, property: property, position: 1) }
    let!(:image3) { create(:property_image, property: property, position: 2) }

    describe 'position management' do
      it 'maintains unique positions within a property' do
        # Move image3 to position 0 (should shift others)
        image3.update!(position: 0)

        # Refresh from database
        images = property.property_images.reload.ordered
        positions = images.pluck(:position)

        expect(positions).to eq(positions.uniq)
        expect(positions.sort).to eq([0, 1, 2])
      end

      it 'handles position gaps appropriately' do
        # Create images with gaps in positions
        image1.update!(position: 0)
        image2.update!(position: 5)
        image3.update!(position: 10)

        new_image = create(:property_image, property: property)
        expect(new_image.position).to eq(11) # Should be next after highest
      end
    end

    describe 'image deletion' do
      it 'maintains correct positions after deletion' do
        image2.destroy

        remaining_images = property.property_images.reload.ordered
        expect(remaining_images.pluck(:position)).to eq([0, 2])
      end

      it 'can optionally reorder after deletion' do
        image2.destroy
        PropertyImage.normalize_positions(property)

        remaining_images = property.property_images.reload.ordered
        expect(remaining_images.pluck(:position)).to eq([0, 1])
      end
    end
  end

  describe 'integration with property' do
    let(:property_with_images) { create(:property, user: user) }
    let!(:primary_image) { create(:property_image, property: property_with_images, position: 0) }
    let!(:secondary_image) { create(:property_image, property: property_with_images, position: 1) }

    it 'property can access primary image' do
      expect(property_with_images.primary_image).to eq(primary_image)
    end

    it 'property can access all images in order' do
      expect(property_with_images.property_images.ordered).to eq([primary_image, secondary_image])
    end

    it 'property can count images' do
      expect(property_with_images.property_images.count).to eq(2)
    end
  end
end