TOKEN="<++>"
GROUP_ID="<++>"
URL="https://api.vk.com/method/"

count=$(curl "${URL}market.get" -F "access_token=${TOKEN}" -F "owner_id=-${GROUP_ID}" -F "count=1" -F "offset=0" -F "v=5.199" | jq -r '.response.count|tonumber')

random_id=$(( RANDOM % count ))

random_product=$(curl "${URL}market.get" -F "access_token=${TOKEN}" -F "owner_id=-${GROUP_ID}" -F "count=1" -F "extended=1" -F "offset=${random_id}" -F "v=5.199")

title=$(echo "$random_product" | jq -r '.response.items[] | .title')
price=$(echo "$random_product" | jq -r '.response.items[] | .price.text')
url=$(echo "$random_product" | jq -r '.response.items[] | .market_url')
photos=$(echo "$random_product" | jq -r '.response.items[] | .photos[] | .orig_photo.url')

photos_data=()
for my_photo in $photos; do
	tempfile="$(mktemp).jpg"
	wget -O "$tempfile" "$my_photo"

	upload=$(curl "${URL}photos.getWallUploadServer" -F "access_token=${TOKEN}" -F "group_id=${GROUP_ID}" -F "v=5.199");
	upload_url=$(echo "$upload" | jq -r '.[].upload_url')
	result=$(curl "${upload_url}" -F "photo=@${tempfile}")
	response=$(curl "${URL}photos.saveWallPhoto" -F "access_token=${TOKEN}" -F "group_id=${GROUP_ID}" -F "photo=$(echo "$result" | jq -r '.photo')" -F "server=$(echo "$result" | jq '.server')" -F "hash=$(echo "$result" | jq '.hash' )" -F "v=5.199")
	id=$(echo "$response" | jq -r '.response[] | .id')
	owner_id=$(echo "$response" | jq -r '.response[] | .owner_id')
	photos_data+=("photo${owner_id}_${id}")
	rm "$tempfile"
done

echo "$title"
echo "$price"
echo "$url"
echo "$photos"

caption="[${url}|${title}]

${price}"

curl "${URL}wall.post" -F "access_token=${TOKEN}" -F "owner_id=-${GROUP_ID}" -F "message=${caption}" -F "from_group=1" -F "attachments=$(printf '%s,' "${photos_data[@]}")" -F "v=5.199"
