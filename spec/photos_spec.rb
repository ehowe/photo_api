require 'spec_helper'

describe 'photos' do
  let(:browser) { Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application)) }
  let(:params)  { {upa_id: "ABC-XYZ-AY-141-SAMPLE-Y"} }

  it "uploads a jpg" do
    file = File.open(File.expand_path('seeds/image500x500.jpg', File.dirname(__FILE__)), 'rb').read

    expect {
      browser.post "/photos", params.merge(photo: file, name: 'regular_sized_jpg.jpg')
    }.to change { Photo.count }.by(1)

    expect(Dir.glob("public/**/*.jpg").map { |i| i.split('/').last }).to contain_exactly("regular_sized_jpg.jpg")

    expect(browser.last_response.body).to match(/image uploaded successfully/)
  end

  it "uploads a png" do
    file = File.open(File.expand_path('seeds/image500x500.png', File.dirname(__FILE__)), 'rb').read

    expect {
      browser.post "/photos", params.merge(photo: file, name: 'regular_sized_png.png')
    }.to change { Photo.count }.by(1)

    expect(Dir.glob("public/**/*.png").map { |i| i.split('/').last }).to contain_exactly("regular_sized_png.png")

    expect(browser.last_response.body).to match(/image uploaded successfully/)
  end

  it "does not upload a tiff" do
    file = File.open(File.expand_path('seeds/image500x500.tiff', File.dirname(__FILE__)), 'rb').read

    browser.post "/photos", params.merge(photo: file, name: 'regular_sized_tiff.tiff')

    expect(browser.last_response.status).to eq(422)
    expect(browser.last_response.body).to match(/unsupported image type/)
  end

  it "does not upload a jpg over 5000x5000" do
    file = File.open(File.expand_path('seeds/image5001x5001.jpg', File.dirname(__FILE__)), 'rb').read

    browser.post "/photos", params.merge(photo: file, name: 'oversized_jpg.jpg')

    expect(browser.last_response.status).to eq(422)
    expect(browser.last_response.body).to match(/maximum supported image size is 5000x5000/)
  end

  it "does not upload a jpg under 350x350" do
    file = File.open(File.expand_path('seeds/image349x349.jpg', File.dirname(__FILE__)), 'rb').read

    browser.post "/photos", params.merge(photo: file, name: 'undersized_jpg.jpg')

    expect(browser.last_response.status).to eq(422)
    expect(browser.last_response.body).to match(/minimum supported image size is 350x350/)
  end

  it "does not upload a png over 5000x5000" do
    file = File.open(File.expand_path('seeds/image5001x5001.png', File.dirname(__FILE__)), 'rb').read

    browser.post "/photos", params.merge(photo: file, name: 'oversized_png.png')

    expect(browser.last_response.status).to eq(422)
    expect(browser.last_response.body).to match(/maximum supported image size is 5000x5000/)
  end

  it "does not upload a png under 350x350" do
    file = File.open(File.expand_path('seeds/image349x349.png', File.dirname(__FILE__)), 'rb').read

    browser.post "/photos", params.merge(photo: file, name: 'undersized_png.png')

    expect(browser.last_response.status).to eq(422)
    expect(browser.last_response.body).to match(/minimum supported image size is 350x350/)
  end

  it "does not upload an image with the same name" do
    file = File.open(File.expand_path('seeds/image500x500.png', File.dirname(__FILE__)), 'rb').read

    expect {
      browser.post "/photos", params.merge(photo: file, name: 'regular_sized_png.png')
    }.to change { Photo.count }.by(1)

    expect {
      browser.post "/photos", params.merge(photo: file, name: 'regular_sized_png.png')
    }.not_to change { Photo.count }

    expect(browser.last_response.body).to match(/Name is already taken/)
  end

  context "with some photos" do
    before(:each) do
      %w(image500x500.png image500x500.jpg).each do |i|
        file = File.open(File.expand_path("seeds/#{i}", File.dirname(__FILE__)), 'rb').read
        browser.post "/photos", params.merge(photo: file, name: i)
      end
    end

    it "destroys an image record and its file" do
      photo_record = Photo.first(name: "image500x500.png")
      expect {
        photo_record.destroy
      }.to change { Dir.glob("public/**/*.png").count }.by(-1).and change { photo_record.reload.deleted_at }.from(nil)
    end

    it "gets images" do
      browser.get "/photos"
      body = JSON.parse(browser.last_response.body)["photos"]
      photos = Photo.all
      expect(body.count).to eq(photos.count)
      expect(browser.last_response.header["Link"]).not_to be_nil
      expect(browser.last_response.header["Link"].split(", ").find { |l| l.match(/rel='last'/) }).to match(/page=1/)
    end

    it "paginates images" do
      browser.get "/photos", {per_page: 1}

      body = JSON.parse(browser.last_response.body)["photos"]
      expect(body.count).to eq(1)
      expect(browser.last_response.header["Link"]).not_to be_nil
      expect(browser.last_response.header["Link"].split(", ").find { |l| l.match(/rel='last'/) }).to match(/page=2/)
    end

    it "gets an image record" do
      photo = Photo.first

      browser.get "/photos/#{photo.id}"
      body = JSON.parse(browser.last_response.body)["photo"]

      expect(photo.id).to eq(body["id"])
    end

    it "gets an image content" do
      photo_record = Photo.last
      photo = File.open(File.expand_path("seeds/image500x500.jpg", File.dirname(__FILE__)), 'rb').read

      browser.get photo_record.path

      expect(browser.last_response.body).to eq(photo)
      expect(browser.last_response.header["Content-Type"]).to eq("image/jpeg")
    end
  end
end
