# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

case Rails.env
when "development"
    # development seeds
    users = User.create([
        {email: "admin@admin.com", name: "ad min", password: "adminpassword", password_confirmation: "adminpassword", role: 99}, 
        {email: "intern@intern.com", name: "in tern", password: "intern", password_confirmation: "intern", role: 3},
        {email: "volunteer@volunteer.com", name: "volu nteer", password: "volunteer", password_confirmation: "volunteer", role: 2},
        {email: "organization@organization.com", name: "organi zation", password: "organization", password_confirmation: "organization", role: 1},
        {email: "guest@guest.com", name: "gu est", password: "guestpassword", password_confirmation: "guestpassword", role: 0},
    ])
when "production"
    # production seeds 
    # RAILS_ENV=production bin/rails db:seed
    users = User.create([
        {email: "admin@admin.com", name: "ad min", password: "changeme", password_confirmation: "changeme", role: 99}, 
    ])
end

metadata_types = MetadataType.create([
    {name: "Collection Type", order: 1, user_id: 1},
    {name: "Education Type", order: 1, user_id: 1},
    {name: "Primary User", order: 1, user_id: 1},
    {name: "Resource Type", order: 1, user_id: 1},
    {name: "Rights Statement", order: 1, user_id: 1},
    # {name: "", order: 1, user_id: 1},
])

def create_metadata(name, metadata_type, user_id)
    Metadatum.create(name: name, metadata_type: metadata_type, user_id: user_id)
end

education_types = ["Lower Primary School Student","Upper Primary School Student","Middle School Student","Secondary School Student","College/Upper Division","Adult Education","Career/Technical","Graduate/Professional","Preschool","Kindergarten","Grade 01","Grade 02","Grade 03","Grade 04","Grade 05","Grade 06","Grade 07","Grade 08","Grade 09","Grade 10","Grade 11","Grade 12"]
education_types.each do |education_type|
    create_metadata(education_type, metadata_types.find {|metadata| metadata.name == "Education Type"}, 1)
end

collection_types = ["Arizona Crisis Response Collection","Rwanda Agricultural Collection","Latin America Educational Library","Peace Corps Collection","Namibia Educational Collection","Lesotho Educational Collection","Malawi Educational Collection","Malawi Health Collection","General Agricultural Library","General Health Library","General Educational Library","Middle East Educational Library","Northeast Syria Collection","Southern Africa Educational Collection","Mexico Educational Collection","Pacific Islands Educational Collection","East Africa Educational Collection","Arizona Health Collection","Community Health Collection"]
collection_types.each do |collection_type|
    create_metadata(collection_type, metadata_types.find {|metadata| metadata.name == "Collection Type"}, 1)
end

primary_users = ["Student","Instructor","Parent","Peace Corps Volunteer","Community Member","Field Extension Worker","Farmer"]
primary_users.each do |primary_user|
    create_metadata(primary_user, metadata_types.find {|metadata| metadata.name == "Primary User"}, 1)
end

resource_types = ["Activity","Video","Lesson Plan","Book","Fiction","Curriculum","Article","Fact Sheet","Textbook","Manual","Map","Report","Course","Syllabus","Lecture","Lecture Notes","Audiobook","Article","Student Guide","Case Study","Teaching Guide","كتاب مدرسي","Affiche","Fiche Descriptive","Livre","Activité","Histoire","Manuel","Prèsentation","Contrôle","Vidéo","Plan de Leçon","Manuel Scolaire","المنهج.الدراسي","قصة","كتيب/دليل","فعالية/نشاط","كتاب","الكتاب.المدرسي","فعالية/نشاط","منهج.دراسي","قصة","Infographic","منهج.دراسي","Podcast","Reference Guide","Hoja de Cálculo","Plan de Lección","Artículo","Libro","Reporto","Libro de Audio","Actividad","Mapa","فيديو","Articulo","Activdad","قصص القصيرة","ورقة عمل","Song","Infográfico","Poem","Guión","Igitabo","Amashusho","Inyangiko","Gahunda y’isomo","Urupapuro rw’amakurushingiro","Ishusho","Short Story","Storybook","Dataset"]
resource_types.each do |resource_type|
    create_metadata(resource_type, metadata_types.find {|metadata| metadata.name == "Resource Type"}, 1)
end

rights_statements = ["All rights reserved - permission granted to share on SolarSPELL library for educational purposes only.","Can be shared for educational purposes only.","Public domain.","CC BY - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, so long as attribution is given to the creator. The license allows for commercial use.","CC BY SA - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, so long as attribution is given to the creator. The license allows for commercial use. If you remix, adapt, or build upon the material, you must license the modified material under identical terms.","CC BY NC SA - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format for noncommercial purposes only, and only so long as attribution is given to the creator. If you remix, adapt, or build upon the material, you must license the modified material under identical terms. ","CC BY NC - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format for noncommercial purposes only, and only so long as attribution is given to the creator. ","CC BY ND - This license allows reusers to copy and distribute the material in any medium or format in unadapted form only, and only so long as attribution is given to the creator. The license allows for commercial use. ","CC BY NC ND - This license allows reusers to copy and distribute the material in any medium or format in unadapted form only, for noncommercial purposes only, and only so long as attribution is given to the creator."]
rights_statements.each do |rights_statement|
    create_metadata(rights_statement, metadata_types.find {|metadata| metadata.name == "Rights Statement"}, 1)
end