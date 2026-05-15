# parking_owner_app



# AI 프롬프트
ai/*.md 파일들을 참고하고, backend_server 프로젝트를 참고해서, parking_owner_app 프로젝트에

# 백엔드 서버 실행 방법
cd backend_server
cp .env.example .env        # 환경변수 설정

## 개발 (MariaDB + MinIO만 Docker로 띄우고 API는 로컬 실행)
docker-compose up db minio -d
docker exec -it parking_owner_db mariadb -u root -proot_pw -e "GRANT ALL PRIVILEGES ON *.* TO 'parkingowner'@'%'; FLUSH PRIVILEGES;"
npm install
npm run db:migrate          # DB 스키마 생성
npm run db:seed             # admin 계정 + 샘플 단지 생성
npm run dev                 # 개발 서버 시작 (http://localhost:3000)

## 전체 Docker로 실행
docker-compose up --build
